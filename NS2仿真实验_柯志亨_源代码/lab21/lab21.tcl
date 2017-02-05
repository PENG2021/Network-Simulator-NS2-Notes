#�������ݾ�
#   Video               MyUdpSink
#   W(0) ------ HA------MH(0)

#�]�wbase station���ƥ�
set opt(num_FA) 1

#Ū���ϥΪ̳]�w���Ѽ�
proc getopt {argc argv} {
	global opt
        lappend optlist nn
        for {set i 0} {$i < $argc} {incr i} {
		set opt($i) [lindex $argv $i]
	}
}

getopt $argc $argv

#�]�wGood ->Good�����v 
set pGG $opt(0)

#�]�wBad -> Bad�����v
set pBB $opt(1)

#Good->Bad�����v��pGB=1-pGG;
#Bad->Good�����v��pBG=1-pBB;
#�bsteady state�ɦbGood state�����v��piG=pBG/(pBG+pGB);
#�bsteady state�ɦbBad state�����v��piB=pGB/(pBG+pGB);

#�bGood state,��packet�o��error�����v
set pG $opt(2)

#�bbad state,��packet�o��error�����v
set pB $opt(3)

set seed $opt(4)
set max_fragmented_size $opt(5)
set packetSize [expr $max_fragmented_size+28]

#loss_model: 0 for uniform distribution, 1 for GE model
set loss_model  0

#comm_type: 0 for broacdcast, 1 for unicast
set comm_type 0

#���ͤ@�Ӽ���������
set ns_ [new Simulator]

#�ϥ�hierarchial addressing���覡�w�}
$ns_ node-config -addressType hierarchical

puts [ns-random $seed]

#�]�w�����domain,�C��domain�U���@��cluster
#�Ĥ@��cluster(wired)���@��node,�ĤG��cluster(wireles)�����node (base state + mobile node)
AddrParams set domain_num_ 2
lappend cluster_num 1 1
AddrParams set cluster_num_ $cluster_num
lappend eilastlevel 1 2
AddrParams set nodes_num_ $eilastlevel

#�]�w�O����,������L�{���O���U��
set tracefd [open bsc_multicast.tr w]
$ns_ trace-all $tracefd

#�]�wmobile node���Ӽ�
set opt(nnn) 1

# �ݾ몺�d�� 100m x 100m
set topo [new Topography]
$topo load_flatgrid 100 100

#create god
set god_ [create-god [expr $opt(nnn)+$opt(num_FA)]]

# wired nodes
set W(0) [$ns_ node 0.0.0]

# create channel 
set chan_ [new Channel/WirelessChannel]

#�]�w�`�I�Ѽ�
$ns_ node-config -mobileIP ON \
	          -adhocRouting DSDV \
                  -llType LL \
                  -macType Mac/802_11 \
                  -ifqType Queue/DropTail/PriQueue \
                  -ifqLen 2000 \
                  -antType Antenna/OmniAntenna \
		  -propType Propagation/TwoRayGround \
		  -phyType Phy/WirelessPhy \
                  -channel $chan_ \
	 	  -topoInstance $topo \
                  -wiredRouting ON\
		  -agentTrace OFF \
                  -routerTrace OFF \
                  -macTrace OFF

#�]�wbase station�`�I
set HA [$ns_ node 1.0.0]
set HAnetif_ [$HA set netif_(0)]
$HAnetif_ set-error-level $pGG $pBB $pG $pB $loss_model

#�]�wmobile node���Ѽ�
#���ݭnwired routing,�ҥH�⦹�\��off
$ns_ node-config -wiredRouting OFF
set MH(0) [$ns_ node 1.0.1]
set MHnetif_(0) [$MH(0) set netif_(0)]
$MHnetif_(0) set-error-level $pGG $pBB $pG $pB $loss_model
#�⦹mobile node��e����base station�`�I���s��
[$MH(0)  set regagent_] set home_agent_ [AddrParams addr2id [$HA node-addr]]

#�]�wbase station����m�b(100.0, 100.0)
$HA set X_ 100.0
$HA set Y_ 100.0
$HA set Z_ 0.0

#�]�wmobile node����m�b(80.0, 80.0)
$MH(0) set X_ 80.0
$MH(0) set Y_ 80.0
$MH(0) set Z_ 0.0

#�bwired node�Mbase station�����إߤ@���s�u
$ns_ duplex-link $W(0) $HA 10Mb 10ms myfifo
set q1	[[$ns_ link $W(0) $HA] queue]

set udp1 [new Agent/my_UDP]
$ns_ attach-agent $W(0) $udp1
$udp1 set_filename sd
$udp1 set packetSize_ $packetSize

set forwarder_ [$HA  set forwarder_]
puts [$forwarder_ port]
$ns_ connect $udp1 $forwarder_
$forwarder_ dst-addr [AddrParams addr2id [$MH(0) node-addr]]
$forwarder_ comm-type $comm_type

set null1 [new Agent/myEvalvid_Sink] 
$ns_ attach-agent $MH(0) $null1
$null1 set_filename rd
$MH(0) attach $null1 3

set original_file_name foreman_qcif.st
set trace_file_name video1.dat
set original_file_id [open $original_file_name r]
set trace_file_id [open $trace_file_name w]

set pre_time 0

while {[eof $original_file_id] == 0} {
    gets $original_file_id current_line
     
    scan $current_line "%d%s%d%d%f" no_ frametype_ length_ tmp1_ tmp2_
    set time [expr int(($tmp2_ - $pre_time)*1000000.0)]
          
    if { $frametype_ == "I" } {
  	set type_v 1
  	set prio_p 0
    }	

    if { $frametype_ == "P" } {
  	set type_v 2
  	set prio_p 0
    }	

    if { $frametype_ == "B" } {
  	set type_v 3
  	set prio_p 0
    }	
    
    if { $frametype_ == "H" } {
  	set type_v 1
  	set prio_p 0
    }

    puts  $trace_file_id "$time $length_ $type_v $prio_p $max_fragmented_size"
    set pre_time $tmp2_
}

close $original_file_id
close $trace_file_id
set end_sim_time [expr $tmp2_+5.0]
puts "$end_sim_time"

set trace_file [new Tracefile]
$trace_file filename $trace_file_name
set video1 [new Application/Traffic/myEvalvid]
$video1 attach-agent $udp1
$video1 attach-tracefile $trace_file

$ns_ at 0.0 "$video1 start"
$ns_ at $end_sim_time "$video1 stop"
$ns_ at $end_sim_time "$null1 closefile"
$ns_ at $end_sim_time "$q1 printstatus"
$ns_ at $end_sim_time "$null1 printstatus"
$ns_ at $end_sim_time.1 "$MH(0) reset";
$ns_ at $end_sim_time).0001 "$W(0) reset"
$ns_ at $end_sim_time.0002 "stop "
$ns_ at $end_sim_time.0003  "$ns_  halt"

#�]�w�@��stop���{�� 
proc stop {} {
    global ns_
    global tracefd
    
    #�����O���� 
    close $tracefd
}

#�������
$ns_ run
