BEGIN {
	ORS = ""
	OFS = ""
}

// {
	print "'"$0"', "
}

NR % 2 == 1 {
	print "\n"
}
