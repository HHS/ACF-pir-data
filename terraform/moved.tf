# State moves for resources renamed when query.tf was split into
# main.tf / s3.tf / lambda_query.tf. These keep PirQuery's API Gateway
# (invoke URL, API keys) and WAF in place instead of destroying and
# recreating them. Safe to delete after one successful apply.

moved {
  from = aws_api_gateway_rest_api.lambda
  to   = aws_api_gateway_rest_api.pir_query
}

moved {
  from = aws_api_gateway_stage.lambda
  to   = aws_api_gateway_stage.pir_query
}

moved {
  from = aws_cloudwatch_log_group.api_gw
  to   = aws_cloudwatch_log_group.pir_query_api_gw
}

moved {
  from = aws_lambda_permission.api_gw
  to   = aws_lambda_permission.pir_query_api_gw
}

moved {
  from = aws_wafv2_ip_set.allowed
  to   = aws_wafv2_ip_set.pir_query_allowed
}

moved {
  from = aws_wafv2_web_acl.pir_query_acl
  to   = aws_wafv2_web_acl.pir_query
}

moved {
  from = aws_wafv2_web_acl_association.api_gw
  to   = aws_wafv2_web_acl_association.pir_query
}
