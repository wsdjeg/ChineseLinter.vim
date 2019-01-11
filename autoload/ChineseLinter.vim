scriptencoding utf-8

""
" 指定需要忽略的错误、警告的编号，默认没有禁止。
" >
"   let g:chinese_linter_disabled_nr = ['E001']
" <
"
" 目前支持的检查包括：
" >
"   E001  |  中文字符后存在英文标点
"   E002  |  中英文之间没有空格
"   E003  |  中文与数字之间没有空格
"   E004  |  中文标点两侧存在空格
"   E005  |  行尾含有空格
"   E006  |  数字和单位之间存在空格
"   E007  |  数字使用了全角字符
"   E008  |  汉字之间存在空格
"   E009  |  中文标点重复
"   E010  | 英文标点符号两侧的空格数量不对
"   E011  | 中英文之间空格数量多于 1 个
" <
let g:chinese_linter_disabled_nr = get(g:,'chinese_linter_disabled_nr', [])

" 中文标点符号（更全）
" let s:CHINEXE_PUNCTUATION = '[\u2014\u2015\u2018\u2019\u201c\u201d\u2026\u3001\u3002\u3008\u3009\u300a\u300b\u300c\u300d\u300e\u300f\u3010\u3011\u3014\u3015\ufe43\ufe44\ufe4f\uff01\uff08\uff09\uff0c\uff1a\uff1b\uff1f\uff5e\uffe5]'
let s:CHINEXE_PUNCTUATION = '[\u2010-\u201f\u2026\uff01-\uff0f\uff1a-\uff1f\uff3b-\uff40\uff5b-\uff65]'

" 英文标点
let s:punctuation_en = '[,:;?!]'

" 中文标点符号
let s:punctuation_cn = '[‘’“”、。《》『』！＂＇（），／：；＜＝＞？［］｛｝]'

" 中文汉字
let s:chars_cn = '[\u4e00-\u9fff]'

" 数字
let s:numbers = '[0-9]'

" 全角数字
let s:numbers_cn = '[\uff10-\uff19]'

" 英文字母
let s:chars_en = '[a-zA-Z]'

" 单位
" TODO: 需要添加更多的单位，单位见以下链接
" https://unicode-table.com/cn/blocks/cjk-compatibility/
" https://unicode-table.com/cn/#2031
" https://unicode-table.com/cn/#2100
let s:symbol = '[%‰‱\u3371-\u33df\u2100-\u2109]'

" 空白符号
let s:blank = '\(\s\|[\u3000]\)'

let s:ERRORS = {
            \ 'E001' : ['中文字符后存在英文标点'         , s:chars_cn . s:blank . '*' . s:punctuation_en                                                                                                  ],
            \ 'E002' : ['中英文之间没有空格'             , '\(' . s:chars_cn . s:chars_en . '\)\|\(' . s:chars_en . s:chars_cn . '\)'                                                                     ],
            \ 'E003' : ['中文与数字之间没有空格'         , '\(' . s:chars_cn . s:numbers . '\)\|\(' . s:numbers . s:chars_cn . '\)'                                                                       ],
            \ 'E004' : ['中文标点两侧存在空格'           , '\(' . s:blank . '\+\(' . s:CHINEXE_PUNCTUATION . '\@=\)\)\|\(' . s:CHINEXE_PUNCTUATION . s:blank . '\+\)'                                     ],
            \ 'E005' : ['行尾有空格'                     , s:blank . '\+$'                                                                                                                                ],
            \ 'E006' : ['数字和单位之间有空格'           , s:numbers . s:blank . '\+\ze' . s:symbol                                                                                                       ],
            \ 'E007' : ['数字使用了全角数字'             , s:numbers_cn . '\+'                                                                                                                            ],
            \ 'E008' : ['汉字之间存在空格'               , s:chars_cn . s:blank . '\+\ze' . s:chars_cn                                                                                                    ],
            \ 'E009' : ['中文标点符号重复'               , '\(' . s:punctuation_cn . '\)' . s:blank . '*' . '\1\+' . '\|' . '[、，：；。！？]\{2,}'                                                       ],
            \ 'E010' : ['英文标点符号两侧的空格数量不对' , '\(' . s:blank . '\+\(' . s:punctuation_en . '\@=\)\)\|\(' . s:punctuation_en . s:blank . '\+$\)\|\(' . s:punctuation_en . s:blank . '\{2,}\)' ],
            \ 'E011' : ['中英文之间空格数量多于 1 个'    , '\(' . s:chars_cn . s:blank . s:blank . '\+\(' . s:chars_en . '\@=\)\)\|\(' . s:chars_en . s:blank . s:blank . '\+\(' . s:chars_cn . '\@=\)\)' ],
            \ }

function! s:getNotIgnoreErrors()
    let s:notIgnoreErrors = []
    for l:error_nr in keys(s:ERRORS)
        if index(g:chinese_linter_disabled_nr, l:error_nr) == -1
            call add(s:notIgnoreErrors, l:error_nr)
        endif
    endfor
endfunction
        
function! ChineseLinter#check(...) abort
    call s:getNotIgnoreErrors()
    let s:file = getline(1,'$')
    let s:bufnr = bufnr('%')
    let s:linenr = 0
    let s:colnr = 0
    let s:qf = []
    for l:line in s:file
        let s:linenr += 1
        call s:parser(l:line)
    endfor
    let s:linenr = 0
    let s:colnr = 0
    if !empty(s:qf)
        let g:wsd = s:qf
        call s:update_qf(s:qf)
        copen
    else
        call setqflist([])
        cclose
    endif
endfunction

function! s:parser(line) abort
    for l:error_nr in s:notIgnoreErrors
        call s:find_error(l:error_nr, a:line)
    endfor
endfunction

function! s:find_error(nr, line) abort
    let l:error = s:ERRORS[a:nr]
    let s:colnr = matchend(a:line, l:error[1])
    if s:colnr != -1
        call s:add_to_qf(a:nr)
    endif
endfunction

function! s:add_to_qf(nr) abort
    let l:error_item = {
                \ 'bufnr': s:bufnr,
                \ 'lnum' : s:linenr,
                \ 'col'  : s:colnr,
                \ 'vcol' : 0,
                \ 'text' : a:nr . ' ' . s:ERRORS[a:nr][0],
                \ 'nr'   : a:nr,
                \ 'type' : 'E',
                \ }
    call add(s:qf, l:error_item)
endfunction

" TODO 加入语法分析


function! s:update_qf(dict) abort
    call setqflist(a:dict)
endfunction
