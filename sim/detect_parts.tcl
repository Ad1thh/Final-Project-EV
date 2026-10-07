set all_parts [get_parts]
set families {}
foreach p $all_parts {
    set fam [get_property FAMILY $p]
    if {[lsearch -exact $families $fam] == -1} {
        lappend families $fam
    }
}
puts "INSTALLED FAMILIES: $families"
puts "XC7A PARTS: [lrange [get_parts *xc7a*] 0 10]"
puts "XC7K PARTS: [lrange [get_parts *xc7k*] 0 10]"
