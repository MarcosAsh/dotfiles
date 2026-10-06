" Isabelle theory files (.thy) and session ROOT files: outer syntax only. Inner terms in
" "..." and cartouches are shown as strings; symbols are concealed as Unicode.
if exists("b:current_syntax") | finish | endif

syn keyword isabelleHeader theory imports keywords begin end session sessions theories options description directories document_files
syn keyword isabelleDecl lemma theorem corollary proposition schematic_goal definition abbreviation fun function primrec datatype codatatype type_synonym typedecl record locale context interpretation sublocale class instantiation instance inductive inductive_set coinductive consts axiomatization lemmas declare notation no_notation syntax translations text section subsection subsubsection paragraph chapter ML ML_file ML_val
syn keyword isabelleProof proof qed by apply done oops sorry next have show hence thus obtain fix assume presume define let note then from with using unfolding also finally moreover ultimately case where termination
syn keyword isabelleSpec assumes shows fixes obtains and is for if in includes defines
syn match isabelleProof "\.\.\|\<\.\>"
syn region isabelleComment start="(\*" end="\*)" contains=isabelleComment,@Spell
syn region isabelleString start=+"+ skip=+\\"+ end=+"+
syn region isabelleCartouche matchgroup=Delimiter start="\\<open>" end="\\<close>" contains=isabelleCartouche
syn match isabelleComment "\\<comment>.*$"

hi def link isabelleHeader Include
hi def link isabelleDecl Keyword
hi def link isabelleProof Statement
hi def link isabelleSpec Type
hi def link isabelleComment Comment
hi def link isabelleString String
hi def link isabelleCartouche String

runtime! after/syntax/isabelle_symbols.vim
let b:current_syntax = "isabelle"
