#!/bin/python

import sys
import sqlparse

query = sys.argv[1]

print(sqlparse.format(sqlparse.split(query)[0], reindent=True, keyword_case='upper'))

