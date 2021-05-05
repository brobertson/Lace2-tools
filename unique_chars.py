#!/usr/bin/python
# coding=UTF-8
import sys
import unicodedata
import codecs


def is_greek_char(char):
    import re
    return bool(re.match('([\u0373-\u03FF]|[\u1F00-\u1FFF]|\u0300|\u0301|\u0313|\u0314|\u0345|\u0342|\u0308)', char, re.UNICODE))


def is_common_punct(char):
    return char in u' 0123456789\'ʼ-.,;:)([]·'


#sys.stdin = codecs.getreader("utf-8")(sys.stdin)
data = sys.stdin.readlines()
all_data = ""
for line in data:
    all_data = all_data + line
print("'"+all_data+"'")
inter = list(all_data)
inter.sort()
total_greek = 0
total_cp = 0
for char in inter:
    if (is_greek_char(char)):
        total_greek = total_greek + 1
    if (is_common_punct(char)):
        total_cp = total_cp + 1
print("total chars:", len(inter))
print("total greek:", total_greek)
print("total common punct:", total_cp)
print("uniquely greek + punct:", total_greek + total_cp)
not_greek = len(inter) - (total_greek + total_cp)
print("portion def. not Greek,", float(not_greek)/float(len(inter)))
out = set(inter)
print(len(out))
print(out)
names = []
aword = u""
greek_count = 0
not_greek_count = 0
for char in out:
    if not char == '\n':
        print(char)
        name = 'unknown'
        try:
            name = unicodedata.name(char)
        except:
            print("this is a problem character: " + str('%04x' % ord(char)))
        names.append(name + " " + str('%04x' % ord(char)))
        aword = aword + char
        print(name)
        if (is_greek_char(char)):
            greek_count = greek_count + 1
        elif (not is_common_punct(char)):
            print("\t this is not a greek char")
names.sort()
for name in names:
    print(name)
print(aword)
print("there are ", len(aword), " chars")
print("there are ", greek_count, " total greek chars")
print("there are ", len(aword) - greek_count, " other chars")
