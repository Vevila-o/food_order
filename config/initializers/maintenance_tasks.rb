# Maintenance Tasks 的畫面（/tasks）預設繼承 ActionController::Base，也就是不受全站 Basic Auth 保護。
# 改成繼承 ApplicationController，才會套用 BasicAuthCredentialsService。
MaintenanceTasks.parent_controller = "ApplicationController"
