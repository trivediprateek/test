#!/bin/bash
#List of POS:
#List of Separators:
# ()	NON,PRN separator
# {}	X separator
# []	NCL separator
# --	PRP separator
# ..	WHO separator
# %%	Z separator
# Cc	CON separator
# nn	NVN separator

#############################################
#	Clause Identification
#############################################

echo $1
echo $2
declare -a NVN
declare -a pos_tag
idx=0
j=0
pos_tag="$1"
echo "###########################">>op
echo pos_tag::: $pos_tag>>op
pos_tag=`echo "$pos_tag " | sed 's/\([A-Za-z0-9]*\)-\([A-Za-z0-9]*\) /\1 /g'`
sp_tag=`echo "$pos_tag " | sed 's/\([A-Za-z0-9]*\)-\([A-Za-z0-9]*\) /\2 /g'`
echo pos_tag $pos_tag
echo sp_tag $sp_tag
for i in $pos_tag
do
j=$(($j+1))
tagstr=$tagstr$i$j
done
echo tagstr: $tagstr
#=======================================================================================


# (a). Identify atomic Noun parts (X), such as "a regularly visited grocery shop"
# a lengthy (badly written) code
# a lengthy (badly written) filthy code
# a lengthy (badly written) filthy (badly summarized) code
# a lengthy (badly written) and (badly summarized) code
# a lengthy (badly written),filthy and (badly summarized) code
# ie. a sequence of ADV VRB and ADJ separated by , and CON

tmpX=`echo $tagstr | sed 's/\(ART\([0-9]*\)\)*\(ADV\([0-9]*\)\)*\(ADJ\([0-9]*\)\)*NON\([0-9]*\)/X{\2\4\6(\7)}/g'`;

l1=`echo $tmpX | sed 's/\(ART\([0-9]*\)\)*\(ADV\([0-9]*\)\)*\(ADJ\([0-9]*\)\)*PRN\([0-9]*\)/X{\2\4\6(\7)}/g'`;
echo L1: $l1

# (b). Identify series of X joined by Prepositions (Noun Clauses). eg. "a rugularly visited grocery shop ON the recently built broad road" ,"... quickly the man ON the road" , "... the man quickly IN the car ON the road ..."

l1_temp=`echo $l1 | sed 's/\(\(\(ADV[0-9]*\|PRP[0-9]*X[0-9(){}]*\)*\)X[0-9(){}]*\(\(ADV[0-9]*\|PRP[0-9]*X[0-9(){}]*\)*\)\)/ \1 /g'`
echo l1_temp $l1_temp
# man on the road with an axe
# on the road the man with an axe

# Y will be the X not preceding with a PRP[0-9]*

#=======================================================================================

# (c). For each series (Noun Clauses) identified above, find Y. Y is the main X in a sequence of Nc's joined by PRPs eg. "on the road the man in a car" , Y will be "the man" and whole string will be: Y(the man)-in-(the car)-on-(the road) 

l2=`echo $l1_temp|sed 's/ /\n/g' | sed 's/^X/Y/' | sed 's/\(ADV[0-9]*\|X[0-9(){}]*\)X/\1Y/' | sed 's/PRP\([0-9]*\)X/-\1-/g' | sed 's/\(.*\)\(Y[0-9(){}]*\)\(.*\)/\2\1\3/g' | sed 's/\(.*\)ADV\([0-9]*\)\(.*\)/\1\3a\2a/g'|tr -d '\n'`

echo "******" $l2

#=======================================================================================

# (d). Identify the Verb Clauses (Z), eg. "will have been doing" ,etc.  also the Preposition attached to Verb is to be included in the Verb Clauses. eg. "believe in", "went to" etc.

#VRBs = Singular verb(eg. sit)
#VRBd = Dual verb(eg. hit)H
#VRBm = Multiple verb(eg. give)
#VRBt = think(eg.consider,take)
#VRB@ = Vthink(eg.hate,love,appreciate)
#Va = has, Vb = been, Vc = done

tmpZ=`echo $l2 | sed 's/Va\([0-9]*\)\(ADV\)*\([0-9]*\)*Vb\([0-9]*\)\(ADV\)*\([0-9]*\)*Vc\([0-9]*\)VRB\([gtc]\)\([0-9]*\)/Z\8%\9,\1,\3,\4,\6,\7%/g'`;
echo $tmpZ

tmpZ=`echo $tmpZ | sed 's/V\(a\|b\)\([0-9,]*\)\(ADV\)*\([0-9,]*\)*V\(b\|c\)\([0-9,]*\)VRB\([gtc]\)\([0-9,]*\)/Z\7%\8,\2,\4,\6%/g'`;

echo $tmpZ

tmpZ=`echo $tmpZ | sed 's/V\(a\|b\|c\)\([0-9,]*\)\(ADV\)*\([0-9,]*\)*VRB\([gtc]\)\([0-9,]*\)/Z\5%\6,\2,\4%/g'`;

echo $tmpZ

l3=`echo $tmpZ | sed 's/\(ADV\([0-9,]*\)\)*VRB\([gtc]\)\([0-9,]*\)/Z\3%\4,\2%/g'`;

# Include PRP in Z ie. He (believed in) me ;he (went to) Goa. (Except for Zc eg. "need to do this")
l3=`echo $l3 | sed 's/\(Z.%\)\([0-9,]*\)\(%PRP\)\([0-9,]*\)/\1\2,\4%/g'`;

# Multiple Verbs together : called and told   i.e. Z CON Z
l3=`echo $l3|sed 's/Zg%\([0-9,]*\)%CON\([0-9]*\)Zg%\([0-9,]*\)%/Zg%\1,\2,\3%/'`
echo L3: $l3
#========================================================================================

# 3. Now that Noun Clauses and Verb Clauses are identified, we align them in the Y---Z---Y format.

echo "Insert dummy Y before WHO if not already present" .eg " I know what you say" to "I know the thing what you say"

l3=`echo $l3|sed 's/\(Y[0-9C()c{}a-]*\)\(WHO[0-9]*\)/\1X\2/g' | sed 's/\([^{X}]\)WHO/\1Y{(0)}WHO/g' | sed 's/X//g'`

echo $l3;

echo "Insert dummy Zt if not already present"

l3=`echo $l3|sed 's/\(Y\([0-9C()c{}a-]*\)WHO\([0-9]*\)\)\(Z[^t]\(%[0-9,]*%\)\)/\1Y{(0)}Zt%0%\4/g'`
echo $l3;

l3=`echo $l3|sed 's/\(Y[0-9C()c{}a-]*WHO[0-9]*\)\(Y[0-9C()c{}a-]*Z[^t]%[0-9,]*%\)/\1Y{(0)}Zt%0%\2/g'`
echo $l3;

echo "Insert dummy Y : Zc 'Y' PRP if not already present. eg. man who wants to kill you = man who wants oneself to kill you"

l3=`echo $l3|sed 's/\(Y\([0-9C()c{}a-]*\)WHO\([0-9]*\)Y\([0-9C()c{}a-]*\)Zt\(%[0-9,]*%\)Zc\(%[0-9,]*%\)\)\(PRP[0-9]*\)/\1Y{(\2)}\7/g'`
echo $l3;

echo "Insert dummy Zc (cause/need/want oneself to) if not already present. eg. man who kill me = man who cause oneself to kill me"

l3=`echo $l3|sed 's/\(Y\([0-9C()c{}a-]*\)WHO\([0-9]*\)Y\([0-9C()c{}a-]*\)Zt\(%[0-9,]*%\)\)\(Z[^c]\(%[0-9,]*%\)\)/\1Zc%0%Y{(\2)}PRP0\6/g'`
echo L3: $l3;

l4=$l3

###############################################

echo " Y WHO Y Zt Zc Y PRP Z PRP Y Y - man who i Zt(thought) Zc(caused) Y(him) PRP(to) Z(give) PRP(to) Y(me) Y(the pen)"

l4=`echo $l4 | sed 's/Y[0-9C()c{}a-]*WHO[0-9]*Y[0-9C()c{}a-]*Zt%[0-9,]*%Zc%[0-9,]*%Y\([0-9C()c{}a-]*\)PRP[0-9]*Z.\(%[0-9,]*%\)Y\([0-9C()c{}a-]*\)Y\([0-9C()c{}a-]*\)/[(N\1n---\2---\4-\3]/g'`
lev2_NVN=`echo $l4|sed 's/\[/\n[/g' |sed 's/\]/]\n/g' | grep "\[" |sed 's/\[\|\]//g'`;
	j=$(($j+1))
	echo L4: $l4

	#BEGIN: To find the think_NVN "t_NVN" i.e "I---caused---(lev2_NVN)"
	t_NVN=`echo $l3 | sed 's/Y[0-9C()c{}a-]*WHO[0-9]*Y\([0-9C()c{}a-]*\)Zt\(%[0-9,]*%\)Zc%[0-9,]*%Y[0-9C()c{}a-]*PRP[0-9]*Z.%[0-9,]*%Y[0-9C()c{}a-]*Y[0-9C()c{}a-]*/[\1---\2]/g'|sed 's/\[/\n[/g' |sed 's/\]/]\n/g' | grep "\[" |sed 's/\[\|\]//g'`;

	j=$(($j+1))
	echo t_NVN:: $j :: $t_NVN

# Add t_NVN into array of NVNs
if [  ! -z "$t_NVN" ] ; then 
	idx=$(($idx+1))
	NVN[$idx]="$t_NVN"
fi

	#END: To find the think_NVN "t_NVN" i.e "I---thought---(lev2_NVN)"

########################################

echo " Y WHO Y Zt Z Y - man who i Zt(thought) caused me to Z(give) Y(pen to me);the man who I thought caused me to believe in you;the man who I thought caused me to kill you;the man who stands. ie. Y WHO VRB Y"

l4=`echo $l4 | sed 's/Y\([0-9C()c{}a-]*\)WHO[0-9]*Y[0-9C()c{}a-]*Zt%[0-9,]*%Zc\(%[0-9,]*%\)Y\([0-9C()c{}a-]*\)PRP[0-9]*Z.\(%[0-9,]*%\)\(Y\([0-9C()c{}a-]*\)\)\{0,1\}/[N\1n---\2---\3>\3---\4---\5]/g'`

	echo L4 :: $l4

	#BEGIN: To find the think_NVN "t_NVN" i.e "I---caused---(lev2_NVN)"
	t_NVN=`echo $l3 | sed 's/Y[0-9C()c{}a-]*WHO[0-9]*Y\([0-9C()c{}a-]*\)Zt\(%[0-9,]*%\)Zc%[0-9,]*%Y[0-9C()c{}a-]*PRP[0-9]*Z.%[0-9,]*%Y[0-9C()c{}a-]*/[\1---\2]/g'|sed 's/\[/\n[/g' |sed 's/\]/]\n/g' | grep "\[" |sed 's/\[\|\]//g'`;

	j=$(($j+1))
	echo t_NVN:: $j :: $t_NVN

# Add t_NVN into array of NVNs
if [  ! -z "$t_NVN" ] ; then 
	idx=$(($idx+1))
	NVN[$idx]="$t_NVN"
fi
	#END: To find the think_NVN "t_NVN" i.e "I---thought---(lev2_NVN)"

########################################

echo "the man who I thought you caused me to believe in;the man who I thought he caused me to kill. ie. Y WHO VRB Y"

l4=`echo $l4 | sed 's/Y\([0-9C()c{}a-]*\)WHO[0-9]*Y[0-9C()c{}a-]*Zt%[0-9,]*%Y\([0-9C()c{}a-]*\)Zc\(%[0-9,]*%\)Y\([0-9C()c{}a-]*\)PRP[0-9]*Z.\(%[0-9,]*%\)/[\2---\3---\4>\4---\5---N\1n]/g'`

echo L4 : $l4
	#BEGIN: To find the think_NVN "t_NVN" i.e "I---caused---(lev2_NVN)"
	t_NVN=`echo $l3 | sed 's/Y[0-9C()c{}a-]*WHO[0-9]*Y\([0-9C()c{}a-]*\)Zt\(%[0-9,]*%\)Zc%[0-9,]*%Y[0-9C()c{}a-]*PRP[0-9]*Z.%[0-9,]*%\(Y[0-9C()c{}a-]*\)*/[\1---\2]/g'|sed 's/\[/\n[/g' |sed 's/\]/]\n/g' | grep "\[" |sed 's/\[\|\]//g'`;

	j=$(($j+1))
	echo t_NVN:: $j :: $t_NVN

# Add t_NVN into array of NVNs
if [  ! -z "$t_NVN" ] ; then 
	idx=$(($idx+1))
	NVN[$idx]="$t_NVN"
fi

	#END: To find the think_NVN "t_NVN" i.e "I---thought---(lev2_NVN)"

########################################

echo "the pen that you thought I gave to him"

l4=`echo $l4 | sed 's/Y\([0-9C()c{}a-]*\)WHO\([0-9]*\)Y\([0-9C()c{}a-]*\)Zt\(%[0-9,]*%\)Y\([0-9C()c{}a-]*\)Zg\(%[0-9,]*%\)Y\([0-9C()c{}a-]*\)/[\5---\6---N\1n-\7]/g'`
echo $l4

	#BEGIN: To find the think_NVN i.e "I---thought---(lev2_NVN)"
	comm="sed 's/Y\([0-9C()c{}a-]*\)WHO\([0-9]*\)Y\([0-9C()c{}a-]*\)Zt\(%[0-9,]*%\)Y\([0-9C()c{}a-]*\)Z.\(%[0-9,]*%\)Y\([0-9C()c{}a-]*\)/[\3---\4---$j]/g'|sed 's/\[/\n[/g' |sed 's/\]/]\n/g' | grep '\[' |sed 's/\[\|\]//g'"
	t_NVN=`eval "echo '$l3' | "$comm`
	j=$(($j+1))
	echo t_NVN :: $j :: $t_NVN

# Add t_NVN into array of NVNs
if [  ! -z "$t_NVN" ] ; then 
	idx=$(($idx+1))
	NVN[$idx]="$t_NVN"
fi

########################################

echo "the man whom I thought you killed"

l4=`echo $l4 | sed 's/Y\([0-9C()c{}a-]*\)WHO\([0-9]*\)Y\([0-9C()c{}a-]*\)Zt\(%[0-9,]*%\)Y\([0-9C()c{}a-]*\)Z.\(%[0-9,]*%\)/[\5---\6---N\1n]/g'`
echo L4: $l4

	#BEGIN: To find the think_NVN i.e "I---thought---(lev2_NVN)"
	comm="sed 's/Y\([0-9C()c{}a-]*\)WHO\([0-9]*\)Y\([0-9C()c{}a-]*\)Zt\(%[0-9,]*%\)Y\([0-9C()c{}a-]*\)Z.\(%[0-9,]*%\)/[\3---\4---$j]/g'|sed 's/\[/\n[/g' |sed 's/\]/]\n/g' | grep '\[' |sed 's/\[\|\]//g'"
	t_NVN=`eval "echo '$l3' | "$comm`
	j=$(($j+1))
	echo t_NVN :: $j :: $t_NVN

# Add t_NVN into array of NVNs
if [  ! -z "$t_NVN" ] ; then 
	idx=$(($idx+1))
	NVN[$idx]="$t_NVN"
fi

	#END: To find the think NVN "t_NVN" i.e "I---thought---(lev2_NVN)"

########################################

echo "the man ie. Y"

l4=`echo $l4 | sed 's/Y\([0-9C()c{}a-]*\)/[\1]/g'`;
echo L4: $l4
# No Level 2 NVN in this case

########################################
## 	START finding Level 1 NVN
########################################

# Keep only the main Noun and in the Level 2 NVNs

l4=`echo $l4 | sed 's/\[\([0-9%,(){}-]\)*N/N/g' | sed 's/n\([0-9%,(){}-]\)*\]//g' | sed 's/\[/N/g' | tr -d ']'`
echo L4: $l4 >>op

#Pass the NVN array for Level 3 NVN
$SH/getLev3NVN.sh "${NVN[@]}">>op
echo %%%%%%%%%%%%%%%%%%
