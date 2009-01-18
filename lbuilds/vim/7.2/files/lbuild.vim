" Vim syntax file
" Language:     tyndur lbuild
" Author:       Antoine Kaufmann <toni@famkaufmann.info>
" Copyright:    Copyright (c) 2008 by Antoine Kaufmann
" Licence:	You may redistribute this under the same terms as Vim itself
"
" Syntax highlighting for lbuilds. Inherits from sh.vim and adds
" in lbuild-specific highlights for certain keywords and functions. Requires
" vim 6.3 or later.
"
" Derived from Gentoo-ebuild syntax file
"

if &compatible || v:version < 603
    finish
endif

if exists("b:current_syntax")
    finish
endif

let is_bash=1
runtime! syntax/sh.vim
unlet b:current_syntax

" Default keywords
syn keyword lbuildCoreKeyword include die

" LBuild-Funktionen
syn keyword LbuildFunctions src_unpack src_configure src_compile src_install


" lutils
syn keyword lbuildClassFuncs lmake lpatch lstrip lunpack
" toolchain-Class
syn keyword lbuildClassFuncs tc-build tc-host tc-cc tc-libdir tc-incdir


" Die duerfen nur gelesen werden
syn match   lbuildError /^\(P\|PN\|PV\|PR\|PVR\|PF\|A\|S\)=/
" Sollte ${P} sein
syn match   lbuildError /\${PN}-\${PV}/
" Trailing spaces
syn match   lbuildError /^.*\s\+$/


syn cluster lbuildThings add=lbuildClassFuncs
syn cluster lbuildThings add=lbuildCoreKeyword,lbuildFunctions,lbuildError
syn cluster shCommandSubList add=@lbuildThings


highlight link lbuildCoreKeyword Keyword
highlight link lbuildClassFuncs Keyword
highlight link lbuildFunctions Special
highlight link lbuildError Error

let b:current_syntax = "lbuild"

