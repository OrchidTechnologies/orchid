sed '/INSERT_USAGE/r examples.sh' README.md.in | sed '/INSERT_USAGE/d' > README.md
