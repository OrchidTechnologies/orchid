package util

import (
	"errors"
	"fmt"
	"strings"
)

func AppendIfUnique(s []string, v string) []string {
	unique := true
	for _, x := range s {
		if strings.EqualFold(x, v) {
			unique = false
		}
	}
	if unique == true {
		return append(s, v)
	}
	return s
}

type ColumnList map[string]int

func Columnize(list ColumnList) (string, error) {
	out := make([]string, 0)
	for s, l := range list {
		if len(s) > l {
			return "", errors.New(fmt.Sprintf("String \"%s\" is longer than length %d", s, l))
		}
		pad := strings.Repeat(" ", (l-len(s))/2)
		outstr := pad + s + pad
		outstr += strings.Repeat(" ", l-len(outstr))
		out = append(out, outstr)
	}
	return strings.Join(out, " "), nil
}
