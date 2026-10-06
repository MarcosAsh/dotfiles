" Isabelle/ML on top of Neovim's Standard ML syntax: cartouches, antiquotations and symbols.
syn region isabelleCartouche matchgroup=Delimiter start="\\<open>" end="\\<close>" contains=isabelleCartouche
syn match isabelleAntiquote "\\<\^[A-Za-z_]\+>"
syn region isabelleAntiquote start="@{" end="}" contains=isabelleCartouche
hi def link isabelleCartouche String
hi def link isabelleAntiquote PreProc
runtime! after/syntax/isabelle_symbols.vim
