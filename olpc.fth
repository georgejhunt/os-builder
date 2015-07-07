\ OLPC XO-1.5 XO-1.75 XO-4 automatic unsigned install script
: zd$  " u:\32001xx1.zd"  ;
: installer
    visible

    ." press 'y' to install" cr  \ avoid accidental damage
    begin  key  [char] y  =  until
    page

    zd$ $fs-update
    page

    .os
    ." install done," cr
    ." please remove USB drive and turn off."
    begin halt again
;
installer