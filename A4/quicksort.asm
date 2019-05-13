#studentName: Ingrid Feng
#studentID: 260803777

# This MIPS program should sort a set of numbers using the quicksort algorithm
# The program should use MMIO

.data
#any any data you need be after this line 
str1:	.asciiz "Welcome to QuickSort\n"
str2: 	.asciiz "\nThe sorted array is: "
str3: 	.asciiz "\nThe array is re-initialized\n"
buffer:	.space 2048		#buffer used to take in the user input
newbuff:.space 2048
array: 	.align 2		#array used to store numbers
	.space 2048
space:	.asciiz "\n"
	
	.text
	.globl main

main:	# all subroutines you create must come below "main"
	li $s0, 21		#print str1 with length 35
	li $s5, 1		#signifying printing str1
	la $a0, str1

print:	lui $t0, 0xffff		#priting all fixed string
loop:	lw $t1, 8($t0)
	andi $t1, $t1, 0x0001
	beq $t1, $zero, loop
	lb $t3, ($a0)
	sb $t3, 12($t0)
	addi $a0, $a0, 1
	subi $s0, $s0, 1
	bne $s0, 0, loop
	
	beq $s5, 2, buff
	beq $s5, 7, aftsor
	beq $s5, 8, start
	beq $s5, 3, start
	
	li $s5, 8		
cleaArr:li $s6, 0		#index that points to the end of last number in the array, set to 0 when 'c' is entered
	la $t0, array		#the array of elements to be cleared
	li $t2, 512		#counter for the length of the array
clean1:	beq $t2, $zero, cleabuf	#when counter goes to 0 i.e. all space is cleaned, can start the next round of query
	sw $zero, ($t0)		#clean the current word
	addi $t0, $t0, 4	#go to next word
	subi $t2, $t2, 1	#decrement the counter
	j clean1
	
aftsor:	li $s5, 8
cleabuf:la $t1, buffer		#the buffer of elements to be cleared
	la $t3, newbuff		#newbuffer to be cleared
	li $t2, 512		#counter for the length of the array
clean:	beq $t2, $zero, check	#when counter goes to 0 i.e. all space is cleaned, can start the next round of query
	sb $zero, ($t1)		#clean the current byte
	addi $t1, $t1, 1	#go to next byte
	sb $zero, ($t3)		#clean the current byte
	addi $t3, $t3, 1	#go to next byte
	subi $t2, $t2, 1	#decrement the counter
	j clean

check:	beq $s5, 8, start	#signifying this is another round of sorting, no need to print str3
print3:	li $s0, 29		#print str3 with length 28
	li $s5, 3		#signifying printing str3
	la $a0, str3
	j print

#when 's' is called and another array is entered, only clear the buffers and maintain the index of array
start:	la $t0, buffer		#t0 is text, t1 is search word

loopRW:	jal Read		# reading and writing using MMIO
	add $a0,$v0,$zero	
	jal Write
	j loopRW

Read:	lui $t2, 0xffff 	#ffff0000
Loop1:	lw $t3, 0($t2) 		#control
	andi $t3,$t3,0x0001
	beq $t3,$zero,Loop1
	lw $v0, 4($t2) 		#data	
	jr $ra

Write:  lui $t2, 0xffff 	#ffff0000
Loop2: 	lw $t3, 8($t2) 		#control
	andi $t3,$t3,0x0001
	beq $t3,$zero,Loop2

	li $s5, 1
	beq $a0, 113, quit	# 'q' is entered	
	beq $a0, 99, cleaArr 	# 'c' is entered
	beq $a0, 115, storing	# 's' is entered
	
	#ignore everything except numbers and spaces
	beq $a0, 32, display
	sltiu $t1, $a0, 58	# if $t2 < 58 then set $t1 to 1
	beq $t1, $zero, jump	# not a digit or space, go to next
	sltiu $t1, $a0, 48	# if $t2 < 48(not a digit 0-9) then set $t1 to 1
	bne $t1, $zero, jump	# not a digit, go to next
	
display:sw $a0, 12($t2) 	# echo
	sb $a0, ($t0)		#else store the digit as ASCII
	addi $t0, $t0, 1
jump:	jr $ra

#store from buffer to array
storing:li $s4, 0
	li $s2, 0
	li $t1, 0
	
calc:	lb $s2, buffer($t1)	#read the current character in buffer
	beq $s2, $zero, sort	#end of buffer
	beq $s2, 32, next	#current is space
	subi $s2, $s2, 48	# get the real digit from ASCII
	
	addi $t1, $t1, 1	#check if next is space or null
	lb $t3, buffer($t1)
	subi $t1, $t1, 1
	beq $t3, $zero, onedig	#next is null means this is either the second digit or this is a one digit number
	beq $t3, 32, onedig	#next is space means this is either the second digit or this is a one digit number
	
	#else this is the tens digit of a two digits number
	mul $s4, $s2, 10
	j next
	
onedig:	beq $s4, $zero, store	#one digit number, then store
	add $s2, $s4, $s2	#two digits number
	j store

store:	sw $s2, array($s6)	# store current number into array	
	add $s4, $zero, $zero	# set $t4 to 0
	addi $s6, $s6, 4	# go to next number in array
next:	addi $t1, $t1, 1	# next character in buffer
	j calc

#now we have stored the numbers user input so far into array, can start sorting
sort:	li $a0, 0		# int low
  	subi $a1, $s6, 4	# int high
  	jal quick
  	j print2

quick:	bgt $a1, $a0, subf	#hi>low then do subf
  	jr $ra
subf:	addi $sp, $sp, -12	#stack pointers
  	sw $ra, ($sp)
  	sw $a0, 4($sp)
  	sw $a1, 8($sp)
  	
  	lw $a0, 4($sp)		#partition
  	lw $a1, 8($sp)
  	jal part
  	move $t5, $v0
  	
  	lw $t6, 4($sp)		#left quicksort
  	lw $t7, 8($sp)
  	move $a0, $t6
  	subi $a1, $t5, 4
  	jal quick
  	
  	lw $t6, 4($sp)		#left quicksort
  	lw $t7, 8($sp)
  	addi $a0, $t5, 4	#right quicksort
  	move $a1, $t7
  	jal quick
  	
  	lw $ra, ($sp)
  	addi $sp, $sp, 12
  	jr $ra

part:	move $t6, $a0		#low
  	move $t7, $a1		#high
  	
  	move $s1, $t6		#p_pos = low
  	lw $s2, array($s1)	#pivot = a[p_pos]
  	
  	addi $t0, $t6, 4	# i = low + 1
loop1:	bgt $t0, $t7, swap1	#for loop, when exit loop, swap(a,low,p_pos)
  	lw $t2, array($t0)	#a[i]
  	blt $t2, $s2, if	#a[i] < pivot
  	addi $t0, $t0, 4	#i++
  	j loop1

swap1:	lw $t3, array($t6)	#a[i]
  	lw $t4, array($s1)	#a[j]
  	sw $t3, array($s1)
  	sw $t4, array($t6)
  	move $v0, $s1
  	jr $ra
  	
if:	addi $s1, $s1, 4	#p_pos++
	#swap(a,p_pos,i)
	lw $t3, array($s1)	#a[i]
  	lw $t4, array($t0)	#a[j]
  	sw $t3, array($t0)
  	sw $t4, array($s1)
  	addi $t0, $t0, 4	#i++
  	j loop1

#printing str2
print2:	li $s0, 22		#print str2 with length 21
	li $s5, 2		#signifying printing str2
	la $a0, str2
	j print

#store the sorted array into buffer
buff:  	li $t0, 0
	li $s1, 0
stonum:	lw $t3, array($t0)
  	beq $t0, $s6, prinew
  	
  	li $t7, 10
  	div $t3, $t7
  	mflo $t6		#t6 is the digit at tens
  	mfhi $t7		#t7 is the digit at ones
  	
  	beq $t6, $zero, stosin
  	addi $t6, $t6, 48	# change to ASCII
  	sb $t6, newbuff($s1)	# store it to the new buffer
  	addi $s1, $s1, 1
  	
stosin:	addi $t7, $t7, 48	
  	sb $t7, newbuff($s1)
  	addi $s1, $s1, 1
  	
  	li $t3, 32		# a space
  	sb $t3, newbuff($s1)
  	addi $s1, $s1, 1
  	addi $t0, $t0, 4
  	j stonum
  	
prinew: li $t3, 10
	sb $t3, newbuff($s1)
	addi $s1, $s1, 1
	move $s0, $s1		#print newbuff with length 2048
	li $s5, 7		#signifying printing newbuff
	la $a0, newbuff
	j print
	
quit: 	nop
