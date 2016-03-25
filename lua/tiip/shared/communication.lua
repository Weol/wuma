TIIP = TIIP or {}

if SERVER then

	function TIIP.SendTable(id,tbl)
		for _,ply in pairs(player.GetAll()) do
			TIIP.SendDataTable(ply,id,tbl)
		end
	end
	
	function TIIP.UpdateTable(id,tbl)
		for _,ply in pairs(player.GetAll()) do
			TIIP.SendDataUpdate(ply,id,tbl)
		end
	end
	
	TIIP.DataQueue = {}
	function TIIP.QueueUpdate(ply,tbl)
		TIIP.DataQueue[ply] = tbl
	end
	
	function TIIP.SendQueue()
		for ply,tbl in pairs(TIIP.DataQueue) do
			
		end		
	end
	
	util.AddNetworkString( "TIIPDataUpdate" )
	function TIIP.SendDataUpdate(ply,id,tbl)
		net.Start( "TIIPDataUpdate" )
			net.WriteString( id )
			net.WriteTable( tbl )
		net.Send(ply)	
	end
	
	util.AddNetworkString( "TIIPSendData" )
	function TIIP.SendDataTable(ply,id,tbl)
		net.Start( "TIIPSendData" )
			net.WriteString( id )
			net.WriteTable( tbl )
		net.Send(ply)	
	end
	
	util.AddNetworkString( "TIIPCommandStream" )
	function TIIP.RecieveCommand(ply)
		local cmd, tbl = TIIP.ExtractValue(net.ReadTable())

	end
	net.Receive( "TIIPCommandStream", TIIP.onRecieveTable )
		
else

	function TIIP.SendCommand(cmd,...)
		local tbl = {cmd, ...}
		net.Start( "TIIPCommandStream" )
			net.WriteTable(tbl)
		net.SendToServer()
	end
	
	function TIIP.RecieveDataUpdate(lenght)
		local id = net.ReadString()
		local tbl = net.ReadTable()
		TIIP.DATA[id] = table.Merge(TIIP.DATA[id],tbl)
		TIIPLog("Data update recieved (ID:%s)! (SIZE: %s bytes)",id,tostring(lenght))
	end
	net.Receive( "TIIPDataUpdate", TIIP.RecieveDataUpdate )
	
	function TIIP.RecieveDataTable(lenght)
		local id = net.ReadString()
		local tbl = net.ReadTable()
		TIIP.DATA[id] = tbl
		TIIPLog("Data table recieved (ID:%s)! (SIZE: %s bytes)",id,tostring(lenght))
	end
	net.Receive( "TIIPSendData", TIIP.RecieveDataUpdate )
	
end