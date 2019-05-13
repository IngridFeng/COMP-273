#name: Ingrid Feng
#studentID: 260803777

.data

#Must use accurate file path.
#file paths in MARS are relative to the mars.jar file.
# if you put mars.jar in the same folder as test2.txt and your.asm, input: should work.
input:	.asciiz "test1.txt" 	#used as input
output:	.asciiz "copy.pgm"	#used as output

buffer:  .space 2048		# buffer for upto 2048 bytes
errOp: 	.asciiz "Error! Open file failed!"
toWrite: .asciiz "P2\n24 7\n15\n"

	.text
	.globl main

main:	la $a0,input		#readfile takes $a0 as input
	jal readfile

	la $a0, output		#writefile will take $a0 as file location
	la $a1, buffer		#$a1 takes location of what we wish to write.
	jal writefile

	li $v0,10		# exit
	syscall

readfile:
	li $v0, 13 		# open_file syscall code = 13
	li $a1, 0 		# file flag = read (0)
	syscall
	move $s0, $v0 		# save the file descriptor. $s0 = file
	slt $t0, $s0, $zero 	# if $s0 < 0, errors, $t0 will be set to 1
	bne $t0, $zero, error	# goes to the procedure error
	
	# read the file
	li $v0, 14		# read_file syscall code = 14
	move $a0, $s0		# file descriptor
	la $a1, buffer  	# The buffer that holds the string of the WHOLE file
	la $a2, 2048		# hardcoded buffer length
	syscall
	
	# print whats in the file
	li $v0, 4		# read_string syscall code = 4
	la $a0, buffer
	syscall
	
	# close the file
    	li $v0, 16         	# close_file syscall code
    	move $a0, $s0      	# file descriptor to close
    	syscall
    	
    	jr $ra			# finish this procedure
  
error: 	li $v0, 4		# print the error message
	la $a0, errOp
	syscall
	
	li $v0, 10		# exit
	syscall 
	

#Open the file to be read,using $a0
#Conduct error check, to see if file exists

# You will want to keep track of the file descriptor*

# read from file
# use correct file descriptor, and point to buffer
# hardcode maximum number of chars to read
# read from file

# address of the ascii string you just read is returned in $v1.
# the text of the string is in  buffer
# close the file (make sure to check for errors)

	

writefile:
    	move $s2, $a1		# save the string in the buffer
    	
	#open file 
    	li $v0, 13           	# open_file syscall code = 13
    	li $a1, 1           	# file flag = write (1)
    	syscall
    	move $s1, $v0        	# save the file descriptor. $s0 = file
    	
    	slt $t0, $s0, $zero 	# if $s0 < 0, errors, $t0 will be set to 1
	bne $t0, $zero, error	# goes to the procedure error
    	
    	#Write the file
    	li $v0, 15		# write_file syscall code = 15
    	move $a0, $s1		# file descriptor
    	la $a1, toWrite		# the string of the header
    	la $a2, 21		# length of the header
    	syscall
    	
    	li $v0, 15		# write_file syscall code = 15
    	move $a0, $s1		# file descriptor
    	move $a1, $s2		# the string of the entries of the matrix
    	la $a2, 2048		# length of the string
    	syscall

    	
	#MUST CLOSE FILE IN ORDER TO UPDATE THE FILE
    	li $v0, 16         	# close_file syscall code
    	move $a0, $s1      	# file descriptor to close
    	syscall
    	
    	jr $ra			# finish this procedure
#open file to be written to, using $a0.
#write the specified characters as seen on assignment PDF:
#P2
#24 7
#15
#write the content stored at the address in $a1.
#close the file (make sure to check for errors)
