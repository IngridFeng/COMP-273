#studentName: Ingrid Feng
#studentID: 260803777

# This MIPS program should count the occurence of a word in a text block using MMIO

.data
#any any data you need be after this line 
str1:	.asciiz "Word count\nEnter the text segment:\n"
str2: 	.asciiz "Enter the search word:\n"
str3: 	.asciiz "The word '"
str4: 	.asciiz "' occurred "
str5: 	.asciiz " time(s).\npress 'e' to enter another segment of text or 'q' to quit.\n"
text: 	.space 600		#maximum 600 characters
searchW:.space 600

	.text
	.globl main

main:	# all subroutines you create must come below "main"	
	li $s0, 35		#print str1 with length 35
	li $s5, 1		#signifying printing str1
	la $a0, str1

print:	lui $t0, 0xffff		#printing all fixed string
loop:	lw $t1, 8($t0)
	andi $t1, $t1, 0x0001
	beq $t1, $zero, loop
	lb $t3, ($a0)
	sb $t3, 12($t0)
	addi $a0, $a0, 1
	subi $s0, $s0, 1
	bne $s0, 0, loop
	
	beq $s5, 2, RWkey	#separate cases for each fixed string
	beq $s5, 3, prikey
	beq $s5, 4, prinum
	beq $s5, 5, final
	
	la $t0, text		#the text user inputted
	la $t1, searchW		#the search word user inputted
	li $t2, 600		#counter for the length of text segment
	
clean:	beq $t2, $zero, start	#when counter goes to 0 i.e. all space is cleaned, can start the next round of query
	sb $zero, ($t0)		#clean the current byte
	sb $zero, ($t1)
	addi $t0, $t0, 1	#go to next byte
	addi $t1, $t1, 1
	subi $t2, $t2, 1	#decrement the counter
	j clean
	
start:	la $t0, text		#t0 is text, t1 is search word
	la $t1, searchW
	
	li $s4, 0
loopRW:	jal Read		# reading and writing using MMIO
	add $a0,$v0,$zero	
	jal Write
	j loopRW

Read:  	lui $t2, 0xffff 	#ffff0000
Loop1:	lw $t3, 0($t2) 		#control
	andi $t3,$t3,0x0001
	beq $t3,$zero,Loop1
	lw $v0, 4($t2) 		#data	
	jr $ra

Write:  lui $t2, 0xffff 	#ffff0000
Loop2: 	lw $t3, 8($t2) 		#control
	andi $t3,$t3,0x0001
	beq $t3,$zero,Loop2
	sw $a0, 12($t2) 	#data	
	
	beq $s4, 1, storkey	#store text into buffer
	beq $a0, 10, key
	sb $a0, ($t0)
	addi $t0, $t0, 1
	jr $ra

storkey:beq $a0, 10, search	#store key into buffer
	sb $a0, ($t1)
	addi $t1, $t1, 1
	jr $ra

#store the keyword for search
key:	li $s0, 23		#print str2 with length 23
	li $s5, 2		#signifying printing str2
	la $a0, str2
	j print
	
RWkey:	li $s4, 1		#read and write search keyword
	la $t1, searchW
	j loopRW
	
search:	la $t0, text
	la $t1, searchW
	li $t6, 0		#count of the search keyword
	
curr:	lb $t3, ($t0)		#$t3 is current byte in the query text
	lb $t4, ($t1)		#$t4 is current byte in the query keyword
	
	beq $t3, $zero, result	#end of text, parse result
	beq $t4, $zero, checkSp	#end of key, check if this is a space
	
	bne $t3, $t4, next	#current bytes are not the same, then go next byte
	
	addi $t1, $t1, 1	#o.w. current bytes are the same, incre pointer of keyword and go next byte
	addi $t0, $t0, 1	
	j curr
	
next:	la $t1, searchW		#reset pointer for keyword if current byte are not the same
	addi $t0, $t0, 1	
	j curr
	 
checkSp:beq $t3, 32, incre	#if there is a space, increment count $t6
	la $t1, searchW		#reset pointer for keyword if not space after it
	j curr

incre:	addi $t6, $t6, 1
	la $t1, searchW		#reset pointer for keyword after incrementing the count
	j next
	
result: bne $t4, $zero, parse	#increment count if the last word is keyword, no need to check for space since already end of text
	addi $t6, $t6, 1
	
	
#parse the count $t6 into three characters maximum since the input text has 600 chars maximum
parse:	li $t7, 100
	li $t4, 0
	div $t6, $t7
	mflo $t4		#t4 is the digit at hundreds
	mfhi $t6		#t6 is the other two digit
	
	li $t7, 10
	div $t6, $t7
	mflo $t6		#t6 is the digit at tens
	mfhi $t7		#t7 is the digit at ones

	li $s0, 10		#print str3 with length 10
	li $s5, 3		#signifying printing str3
	la $a0, str3
	j print
	
prikey:	la $a0, searchW		#print keyword
	lui $t0, 0xffff
loopkey:lw $t1, 8($t0)
	andi $t1, $t1, 0x0001
	beq $t1, $zero, loopkey
	lb $t3, ($a0)
	beq $t3, $zero, print4
	sb $t3, 12($t0)
	addi $a0, $a0, 1
	j loopkey

print4:	li $s0, 11		#print str4 with length 11
	li $s5, 4		#signifying printing str4
	la $a0, str4
	j print

#printing number of occurence
prinum:	beq $t4, $zero, two	#if first digit is zero, go to two
	li $t8, 3
	addi $t4, $t4, 48
	sb $t4, ($a0)
three:	lui $t0, 0xffff		#printing three digit count
loopnum:lw $t1, 8($t0)
	andi $t1, $t1, 0x0001
	beq $t1, $zero, loopnum
	lb $t3, ($a0)
	sb $t3, 12($t0)
	beq $t8, 2, one
	beq $t8, 1, print5
	
two:	beq $t6, $zero, one	#if second digit is also zero, go to one
	addi $t6, $t6, 48
	sb $t6, ($a0)
	li $t8, 2		#signifying printing tens digit
	j three

one:	addi $t7, $t7, 48
	sb $t7, ($a0)
	li $t8, 1		#signifying printing ones digit
	j three
	
print5:	li $s0, 69		#print str5 with length 68
	li $s5, 5		#signifying printing str5
	la $a0, str5
	j print

final:	lui $t0, 0xffff		#receiving the options q and e and exit/go back to main
loopfin:lw $t1, 0($t0)
	andi $t1, $t1, 0x0001
	beq $t1, $zero, loopfin
	lb $a0, 4($t0)
	beq $a0, 113, quit	#both upper case and lower case e and q are considered valid
	beq $a0, 81, quit
	beq $a0, 101, main
	beq $a0, 69, main
	j loopfin
quit: 	nop
