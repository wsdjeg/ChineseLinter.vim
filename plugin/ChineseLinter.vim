""
" 启动检查命令，检查结果会展示在 locallist 内
command! -nargs=? CheckChinese call ChineseLinter#check(<q-args>)
