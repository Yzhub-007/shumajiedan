#!/usr/bin/env bash
# 全链路冒烟测试（运行级 E2E）v2
# 修复：中文 body 经临时 UTF-8 文件传递（规避 Windows curl 参数编码问题）、
#       动态取用户 ID、金额断言用正则。
# 前置：后端已启动且 APP_ORDER_PAYMENT_ENABLED=true
set -u
BASE="http://localhost:8080"
TMPDIR_LOCAL=$(mktemp -d)
PASS=0; FAIL=0

jqpy() { python -c "import sys,json;d=json.load(sys.stdin);print(eval(sys.argv[1]))" "$1" 2>/dev/null; }

req() { # req METHOD PATH TOKEN DATA_FILE_OR_DASH
  local m=$1 p=$2 t=$3 df=$4
  if [ "$t" = "-" ]; then
    curl -s -m 15 -X "$m" "$BASE$p" -H 'Content-Type: application/json;charset=utf-8' ${df:+-d @"$df"}
  else
    curl -s -m 15 -X "$m" "$BASE$p" -H 'Content-Type: application/json;charset=utf-8' -H "Authorization: Bearer $t" ${df:+-d @"$df"}
  fi
}
body() { echo -n "$1" > "$TMPDIR_LOCAL/b.json"; }
check() {
  local name=$1 expect=$2 actual=$3
  if echo "$actual" | grep -qE "$expect"; then PASS=$((PASS+1)); echo "PASS  $name";
  else FAIL=$((FAIL+1)); echo "FAIL  $name  =>  $(echo "$actual" | head -c 300)"; fi
}

echo "=== 1. 健康检查 ==="
H=$(curl -s -m 5 $BASE/actuator/health); check "health UP" '"UP"' "$H"

echo "=== 2. 手机验证码登录（客户/工程师/管理员）==="
body '{"phone":"13700000001"}'
C=$(req POST /api/auth/sms-code - "$TMPDIR_LOCAL/b.json"); check "客户发码" 'success' "$C"
CCODE=$(echo "$C" | jqpy "d['data']['devCode']")
body "{\"phone\":\"13700000001\",\"code\":\"$CCODE\",\"role\":\"CUSTOMER\"}"
CLOGIN=$(req POST /api/auth/login - "$TMPDIR_LOCAL/b.json")
CTOKEN=$(echo "$CLOGIN" | jqpy "d['data']['accessToken']"); check "客户登录" 'success' "$CLOGIN"

body '{"phone":"13700000002"}'
E=$(req POST /api/auth/sms-code - "$TMPDIR_LOCAL/b.json")
ECODE=$(echo "$E" | jqpy "d['data']['devCode']")
body "{\"phone\":\"13700000002\",\"code\":\"$ECODE\",\"role\":\"ENGINEER\"}"
ELOGIN=$(req POST /api/auth/login - "$TMPDIR_LOCAL/b.json")
ETOKEN=$(echo "$ELOGIN" | jqpy "d['data']['accessToken']")
ENGID=$(echo "$ELOGIN" | jqpy "d['data']['userId']"); check "工程师登录" 'success' "$ELOGIN"

body '{"username":"admin","password":"admin123"}'
ALOGIN=$(req POST /admin/auth/login - "$TMPDIR_LOCAL/b.json")
ATOKEN=$(echo "$ALOGIN" | jqpy "d['data']['accessToken']"); check "管理员登录" 'success' "$ALOGIN"
AROLE=$(echo "$ALOGIN" | jqpy "d['data']['adminRole']"); check "管理员角色 SUPER_ADMIN" 'SUPER_ADMIN' "$AROLE"

echo "=== 3. 客户资料/地址/设备类型 ==="
body '{"nickname":"测试厂","companyName":"示例机械厂","contactName":"张工","industry":"机械制造"}'
PR=$(req PUT /api/customer/profile "$CTOKEN" "$TMPDIR_LOCAL/b.json")
check "更新客户资料" 'success' "$PR"
body '{"label":"厂区东门","province":"上海市","city":"上海市","district":"浦东新区","detail":"金桥路1号厂房","lng":121.4737,"lat":31.2304,"isDefault":true}'
AD=$(req POST /api/customer/addresses "$CTOKEN" "$TMPDIR_LOCAL/b.json")
AID=$(echo "$AD" | jqpy "d['data']['id']"); check "新增地址(得id)" 'success' "$AD"
CATS=$(req GET /api/device-categories "$CTOKEN" -)
CID=$(echo "$CATS" | jqpy "[x for x in d['data'] if x['name']=='注塑机'][0]['id']"); check "设备类型树" 'success' "$CATS"

echo "=== 4. 工程师认证 → 后台审核 ==="
body "{\"realName\":\"王师傅\",\"idCardNo\":\"310101199001011234\",\"idCardFrontUrl\":\"/uploads/f.jpg\",\"idCardBackUrl\":\"/uploads/b.jpg\",\"certUrls\":[],\"skillTags\":[\"注塑机\"],\"serviceRadiusKm\":20}"
VF=$(req POST /api/engineer/verify "$ETOKEN" "$TMPDIR_LOCAL/b.json"); check "提交资质" 'success' "$VF"
AP=$(req POST "/admin/engineers/$ENGID/approve" "$ATOKEN" ""); check "管理员审核通过" 'success' "$AP"
VS=$(req GET /api/engineer/verify-status "$ETOKEN" -); check "审核状态 APPROVED" 'APPROVED' "$VS"

echo "=== 5. 工程师上线 + 位置上报（Redis GEO）==="
body '{"online":true,"lng":121.4737,"lat":31.2304}'
ON=$(req PUT /api/engineer/online "$ETOKEN" "$TMPDIR_LOCAL/b.json"); check "上线" 'success' "$ON"
body '{"lng":121.4737,"lat":31.2304}'
LOC=$(req POST /api/engineer/location "$ETOKEN" "$TMPDIR_LOCAL/b.json"); check "位置上报" 'success' "$LOC"

echo "=== 6. 客户发单（触发派单事件）==="
body "{\"deviceCategoryId\":$CID,\"deviceBrand\":\"海天\",\"deviceModel\":\"MA2000\",\"faultDesc\":\"注塑机合模机构异响\",\"mediaUrls\":[],\"addressId\":$AID,\"urgency\":\"URGENT\"}"
OR=$(req POST /api/orders "$CTOKEN" "$TMPDIR_LOCAL/b.json")
OID=$(echo "$OR" | jqpy "d['data']['id']")
check "发布工单(得id)" '"id":[0-9]' "$(echo "$OR" | tr -d ' ')"
NC=$(req GET "/api/orders/$OID/nearby-count" "$CTOKEN" -)
check "附近在线工程师数>=1" '"count":[1-9]' "$(echo "$NC" | tr -d ' ')"

echo "=== 7. 工程师抢单 → 出发 → 到达签到 ==="
POOL=$(req GET /api/engineer/orders/pool "$ETOKEN" -)
check "工单池含新单" "\"id\":$OID" "$(echo "$POOL" | tr -d ' ')"
GB=$(req POST "/api/engineer/orders/$OID/grab" "$ETOKEN" -); check "抢单" 'success' "$GB"
GB2=$(req POST "/api/engineer/orders/$OID/grab" "$ETOKEN" -); check "重复抢单被拒" '30003' "$GB2"
DP=$(req POST "/api/engineer/orders/$OID/depart" "$ETOKEN" -); check "出发" 'success' "$DP"
body '{"lng":121.4737,"lat":31.2304}'
AV=$(req POST "/api/engineer/orders/$OID/arrive" "$ETOKEN" "$TMPDIR_LOCAL/b.json")
check "到达签到(GPS 通过)" 'success' "$AV"
body '{"lng":121.0,"lat":31.0}'
AVF=$(req POST "/api/engineer/orders/$OID/arrive" "$ETOKEN" "$TMPDIR_LOCAL/b.json")
check "远距离签到被拒" '30005' "$AVF"

echo "=== 8. 报价 → 客户确认 → 维修中 ==="
body '{"laborFee":100,"partsFee":50,"partsDetail":["密封圈x2"]}'
QT=$(req POST "/api/engineer/orders/$OID/quote" "$ETOKEN" "$TMPDIR_LOCAL/b.json")
QID=$(echo "$QT" | jqpy "d['data']['id']"); check "提交报价" 'success' "$QT"
QA=$(req POST "/api/orders/$OID/quotes/$QID/accept" "$CTOKEN" -); check "客户确认报价" 'success' "$QA"
DS=$(req GET "/api/orders/$OID" "$CTOKEN" -)
check "工单状态 REPAIRING" '"REPAIRING"' "$DS"
check "订单金额已记录 150" '"quoteAmount":150(\.0+)?' "$(echo "$DS" | tr -d ' ')"

echo "=== 9. 完工 → 验收 → 支付（payment-enabled）==="
body '{"diagnosis":"合模肘杆磨损","solution":"更换密封圈并润滑","beforePhotos":["/uploads/b1.jpg"],"afterPhotos":["/uploads/a1.jpg"],"partsReplaced":["密封圈"]}'
FN=$(req POST "/api/engineer/orders/$OID/finish" "$ETOKEN" "$TMPDIR_LOCAL/b.json")
check "完工提交" 'success' "$FN"
CF=$(req POST "/api/orders/$OID/confirm" "$CTOKEN" -); check "验收通过→待支付" 'success' "$CF"
DS2=$(req GET "/api/orders/$OID" "$CTOKEN" -); check "状态 PENDING_PAYMENT" 'PENDING_PAYMENT' "$DS2"
body '{"channel":"MOCK"}'
PAY=$(req POST "/api/orders/$OID/pay" "$CTOKEN" "$TMPDIR_LOCAL/b.json")
check "MOCK 支付成功" '"paid":true' "$PAY"
DS3=$(req GET "/api/orders/$OID" "$CTOKEN" -)
check "状态 COMPLETED" '"COMPLETED"' "$DS3"
check "平台抽佣 15 已记录" '"platformFee":15(\.0+)?' "$(echo "$DS3" | tr -d ' ')"

echo "=== 10. 工程师钱包入账（150-15=135）==="
WA=$(req GET /api/engineer/wallet "$ETOKEN" -)
check "钱包余额 135" '"balance":135(\.0+)?' "$(echo "$WA" | tr -d ' ')"

echo "=== 11. 双向评价 ==="
body '{"score":5,"tags":["专业高效"],"content":"修得很快"}'
RV=$(req POST "/api/orders/$OID/review" "$CTOKEN" "$TMPDIR_LOCAL/b.json")
check "客户评价工程师" 'success' "$RV"
DS4=$(req GET "/api/orders/$OID" "$CTOKEN" -); check "状态 REVIEWED" 'REVIEWED' "$DS4"

echo "=== 12. 提现申请 → 后台审核（RBAC SUPER_ADMIN）==="
body '{"amount":50,"account":"alipay:wang@example.com"}'
WD=$(req POST /api/engineer/withdrawals "$ETOKEN" "$TMPDIR_LOCAL/b.json")
WID=$(echo "$WD" | jqpy "d['data']['id']"); check "申请提现" 'success' "$WD"
WAB=$(req GET /api/engineer/wallet "$ETOKEN" -)
check "冻结 50" '"frozen":50(\.0+)?' "$(echo "$WAB" | tr -d ' ')"
check "余额 85" '"balance":85(\.0+)?' "$(echo "$WAB" | tr -d ' ')"
WAP=$(req POST "/admin/withdrawals/$WID/approve" "$ATOKEN" -); check "提现审核通过" 'success' "$WAP"
WRJ=$(req POST "/admin/withdrawals/$WID/approve" "$ATOKEN" -); check "重复审核被拒" '40900' "$WRJ"

echo "=== 13. 通知 / 统计 / 越权校验 ==="
NO=$(req GET /api/notifications "$ETOKEN" -); check "工程师收到通知" 'NEW_ORDER' "$NO"
RA=$(req POST /api/notifications/read-all "$ETOKEN" ""); check "全部已读" 'success' "$RA"
ST=$(req GET /admin/stats/overview "$ATOKEN" -)
check "统计含趋势" 'trend' "$ST"
check "统计含工程师排行" 'engineerRanking' "$ST"
E2=$(req GET /api/engineer/orders/pool - -); check "未登录访问被拒" '401' "$E2"
body '{"name":"测试类型"}'
X3=$(req POST "/admin/device-categories" "$ATOKEN" "$TMPDIR_LOCAL/b.json")
check "超管可配价格" 'success' "$X3"

echo "=== 14. 文件上传 ==="
printf '\x89PNG\r\n\x1a\n test' > "$TMPDIR_LOCAL/test.png"
UP=$(curl -s -m 15 -X POST "$BASE/api/upload" -H "Authorization: Bearer $CTOKEN" -F "file=@$TMPDIR_LOCAL/test.png")
UPURL=$(echo "$UP" | jqpy "d['data']['url']")
check "上传返回 URL" '"/uploads/' "$UP"
UPGET=$(curl -s -o /dev/null -w '%{http_code}' "$BASE$UPURL")
check "静态访问上传文件 200" '200' "$UPGET"

echo ""
echo "======================================"
echo "结果：PASS=$PASS FAIL=$FAIL"
[ $FAIL -eq 0 ] && echo "ALL GREEN ✔" || echo "存在问题需修复 ✘"
