# This script is created by NSG2 beta1
# <http://wushoupong.googlepages.com/nsg>

proc getopt {argc argv} {
	global opt
        lappend optlist nn
        for {set i 0} {$i < $argc} {incr i} {
		set opt($i) [lindex $argv $i]
	}
}

getopt $argc $argv

#opt(0):�ʥ]���j�p
#opt(1):��ܭnlong preamble�٬Oshort preamble

#remove useless headers
remove-all-packet-headers            ;# removes all except common
add-packet-header IP LL Mac ARP TCP  ;# needed headers

Mac/802_11 set CWMin_                 31
Mac/802_11 set CWMax_                 1023
Mac/802_11 set SlotTime_              0.000020  ;# 20us
Mac/802_11 set SIFS_                  0.000010  ;# 10us
Mac/802_11 set PreambleLength_        144       ;# 144 bit
Mac/802_11 set ShortPreambleLength_   72        ;# 72 bit
Mac/802_11 set PreambleDataRate_      1.0e6     ;# 1Mbps
Mac/802_11 set PLCPHeaderLength_      48        ;# 48 bits
Mac/802_11 set PLCPDataRate_          1.0e6     ;# 1Mbps
Mac/802_11 set ShortPLCPDataRate_     2.0e6     ;# 2Mbps
Mac/802_11 set RTSThreshold_          3000      ;# bytes Disable RTS/CTS
Mac/802_11 set ShortRetryLimit_       7         ;# retransmissions
Mac/802_11 set LongRetryLimit_        4         ;# retransmissions
Mac/802_11 set newchipset_            false     ;# use new chipset, allowing a more recent
                                                ;# packet to be correctly received in place
                                                ;# of the first sensed packet
Mac/802_11 set dataRate_  11Mb			;# 802.11 data transmission rate
Mac/802_11 set basicRate_ 1Mb                   ;# 802.11 basic transmission rate 
#Mac/802_11 set aarf_ false                      ;# 802.11 Auto Rate Fallback

#opt(1) 1: short preamble 0:long preamble
if {$opt(1) > 0} {
	ErrorModel80211 shortpreamble	1  ;# toggle 802.11 short preamble on/off
}

#===================================
#     Simulation parameters setup
#===================================
set val(chan)   Channel/WirelessChannel    ;# channel type
set val(prop)   Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)  Phy/WirelessPhy            ;# network interface type
set val(mac)    Mac/802_11                 ;# MAC type
set val(ifq)    Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)     LL                         ;# link layer type
set val(ant)    Antenna/OmniAntenna        ;# antenna model
set val(ifqlen) 10                         ;# max packet in ifq
set val(nn)      2                         ;# number of mobilenodes
set val(rp)     DSDV                       ;# routing protocol
set val(stop)   100.0                       ;# time of simulation end


# ���ͤ@�Ӽ���������
set ns_              [new Simulator]

#�w�q�@�ӰO����,�ΨӰO���ʥ]�ǰe���L�{
set tracefd     [open simple.tr w]
$ns_ trace-all $tracefd

#�}�Ҥ@��NAM trace file
set nf [open out.nam w]
$ns_ namtrace-all-wireless $nf 100 100

# set up topography object
#�إߤ@�өݾ몫��
set topo       [new Topography]

# �ݾ몺�d�� 100m x 100m
$topo load_flatgrid 100 100

# Create God
create-god $val(nn)
set chan_1_ [new $val(chan)]


# �]�m�`�I�Ѽ�

        $ns_ node-config -adhocRouting $val(rp) \
                         -llType $val(ll) \
                         -macType $val(mac) \
                         -ifqType $val(ifq) \
                         -ifqLen $val(ifqlen) \
                         -antType $val(ant) \
                         -propType $val(prop) \
                         -phyType $val(netif) \
                         -channel $chan_1_ \
                         -topoInstance $topo \
                         -agentTrace ON \
                         -routerTrace OFF \
                         -macTrace ON \
                         -movementTrace OFF                   
        
        for {set i 0} {$i < $val(nn) } {incr i} {
                set node_($i) [$ns_ node]
                $node_($i) random-motion 0            ;# disable random motion
        }
       
set  rng  [new RNG]
$rng seed 1
set  rand1  [new RandomVariable/Uniform]

for {set i 0} {$i < $val(nn) } {incr i} {
    puts "wireless node $i created ..."
    set x [expr 50+[$rand1 value]*50]
    set y [expr 50+[$rand1 value]*50]
    $node_($i) set X_ $x
    $node_($i) set Y_ $y
    $node_($i) set Z_ 0.0
    puts "X_:$x Y_:$y"
}

for {set i 0} {$i < $val(nn) } {incr i} {
    set udp_($i) [new Agent/UDP]
    $udp_($i) set packetSize_ 2000
    $ns_ attach-agent $node_($i) $udp_($i)
    set null_($i) [new Agent/LossMonitor]
    $ns_ attach-agent $node_($i) $null_($i)
}

for {set i 0} {$i < $val(nn) } {incr i} {
    if {$i == ($val(nn)-1)} {
    	$ns_ connect $udp_($i) $null_(0)
    } else {
    	set j [expr $i+1]
    	$ns_ connect $udp_($i) $null_($j)
    }
    
    set cbr_($i) [new Application/Traffic/CBR]
    $cbr_($i) attach-agent $udp_($i)
    $cbr_($i) set type_ CBR
    #�ϥΪ̩Ҩϩw��packet size�O�]�t�FIP header,�ҥH�n������20bytes
    $cbr_($i) set packet_size_ [expr $opt(0)-20]
    $cbr_($i) set rate_  5Mb
    $cbr_($i) set random_ false
}

for {set i 0} {$i < $val(nn) } {incr i} {    
    $ns_ at 1.1  "$cbr_($i) start"
    $ns_ at 5.1 "$cbr_($i) stop"
}

# Tell nodes when the simulation ends
for {set i 0} {$i < $val(nn) } {incr i} {
    $ns_ at 100.0 "$node_($i) reset";
}

$ns_ at 100.0 "stop"
$ns_ at 100.01 "puts \"NS EXITING...\" ; $ns_ halt"

$ns_ at 45.0 "record"

set first_time 10000.0
set last_time 0.0

proc record {} {
	global ns_ null_ val first_time last_time
 	set sum 0
    	for {set i 0} {$i < $val(nn) } {incr i} { 
    		set th 0
    		#�έp�����ݦ��F�h�֭�bytes
    		set a [$null_($i) set bytes_]
    		#�̫�@�������ʥ]�ɶ�
    		set b [$null_($i) set lastPktTime_]
    		#�Ĥ@�������ʥ]�ɶ�
    		set c [$null_($i) set firstPktTime_]
    		  		
    		#�P�_�t�Τ�,�Ĥ@�������ʥ]�ɶ��@  		
    		if {$first_time>$c} {
    		     set first_time $c
    		}
    		
    		#�P�_�t�Τ�,�̫�@�������ʥ]�ɶ�
    		if {$last_time<$b} {
    		     set last_time $b
    		}
    		
    		if {$b>$c} {
    		#�έp�t�Τ�,�����F�h�֭�bytes
     			set t_bytes [expr $a*8]
     			set sum [expr $sum+$t_bytes]
    	        }
         }
         
    #�έp�t�Τ�,�������]�R�q
    puts "total throughput:[expr $sum/($last_time-$first_time)] bps"
}

proc stop {} {
    global ns_  tracefd
    $ns_ flush-trace
    close $tracefd
}

puts "Starting Simulation..."
$ns_ run
