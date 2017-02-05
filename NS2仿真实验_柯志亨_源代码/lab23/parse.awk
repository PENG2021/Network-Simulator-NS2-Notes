#���R���P���Ѩ�w���į઺AWK�{��
BEGIN{
#�{����l�ơA�]�w�@�ܼƤw�O���ثe�t�Τ��̰��B�z�ʥ]��ID�A
#�Τw�g�ǰe�α����쪺�ʥ]�ӼơC
  	highest_packet_id=0;
	sends=0;
	receives=0;
	routing_packets=0;
	first_received_time=0;
	first=0;
}
{
	action = $1;
	time = $2;
	packet_id = $6;
	trace = $4;
	type = $7;
 		
	if(action=="s" || action== "r" || action=="f" )
	{
	    #�O���ǰe�X���ʥ]�Ӽ�
	    if(action=="s"&&trace=="AGT"&&type=="cbr")
            	{sends++;}

    	    #�O���ثe�t�Τ��̰��B�z�ʥ]��ID
            if(packet_id > highest_packet_id) 
            	{highest_packet_id = packet_id;}

            #�����ʥ]���ǰe�ɶ�
            if(start_time[packet_id] == 0) 
            	{start_time[packet_id] = time;}
                     
            #���������쪺�ʥ]�ӼƤΫʥ]�������ɶ�
	    if (action =="r" && trace== "AGT" && type== "cbr")
	    {
	    	if(first==0){
	    		first_received_time= time;
	    		first=1;
	    	}
		receives++;
		end_time[packet_id] = time;
	    } else 
	    	end_time[packet_id] = -1;
         }
}

END{
          #�p�⦳�īʥ]�����I����I����ɶ�
         for (packet_id = 0; packet_id <= highest_packet_id ; packet_id++) {
           packet_duration = end_time[packet_id] - start_time[packet_id];
           if (packet_duration >0) end_to_end_delay += packet_duration;
         }
        #�p�⦳�īʥ]���������I����I����ɶ�
         avg_end_to_end_delay = end_to_end_delay / (receives);

         #�p��ʥ]�e�F���
         pdfraction = (receives/sends)*100;
	
	#�C�X�Ҧ��p��X���į�ƾ�	
         printf(" Total packet sends: %d \n", sends);
         printf(" Total packet receives: %d \n", receives);
         printf(" Packet delivery fraction: %s \n", pdfraction);
         printf(" Average End-to-End delay:%f s \n" , avg_end_to_end_delay);
         printf(" first packet received time:%f s\n", first_received_time);     
}
