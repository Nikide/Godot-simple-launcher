extends Node2D

var http_client = HTTPClient.new()
var update_headers : Dictionary = {}
var host = "" #s3 storage bucket url like bucket.hb.ru-msk.vkcloud-storage.ru
var file_name = "" # Game exe file like game.exe
func pbar(val,maxvall): #For simple manipulate progress bar
	$CanvasLayer/Control/Panel/LoadingState/ProgressBar.value = val
	$CanvasLayer/Control/Panel/LoadingState/ProgressBar.max_value = maxvall
func state(txt,code = null): #Setting state text
	print(txt) #to console to
	if code:
		$CanvasLayer/Control/Panel/LoadingState/StateText.text = txt+str(code)
	else:
		$CanvasLayer/Control/Panel/LoadingState/StateText.text = txt
func _ready() -> void:
	#First check file fersion on bucker
	$Downloader.download_file = "user://"+file_name # set file to download
	state("init")
	pbar(0,1) #Set pbar zero
	var error = http_client.connect_to_host(host,443,TLSOptions.client())
	if error != OK:
		state("Check version error:",error)
		return
	state("Begin version check")
	while http_client.get_status() == HTTPClient.STATUS_CONNECTING or http_client.get_status() == HTTPClient.STATUS_RESOLVING:
		http_client.poll()
		pbar(http_client.get_status(),7)
		state("Connected")
		
	if http_client.get_status() != HTTPClient.STATUS_CONNECTED:
		state("Failed to connect: ", http_client.get_status())
		return

	# Send a GET request
	var headers = ["User-Agent: SimpleLauncher/1.0"] # set user-agent change if need
	error = http_client.request(HTTPClient.METHOD_GET, "/"+file_name, headers)
	if error != OK:
		state("Error sending request for version check: ",error)
		return
	# Wait for response
	while http_client.get_status() == HTTPClient.STATUS_REQUESTING:
		state("Getting version info ")
		pbar(http_client.get_status(),7)
		http_client.poll()
	if http_client.get_status() != HTTPClient.STATUS_BODY:
		state("Get version request failed: ",http_client.get_status())
		print(http_client.get_response_headers())
		return
	# Get response details
	var head : PackedStringArray = http_client.get_response_headers() #Write headers
		
	state("Version getted")
	pbar(1,1) #Set pbar full
	http_client.close()
	for i in range(0,head.size()):
		update_headers[head[i].split(":")[0].strip_edges()] = head[i].split(":")[1].strip_edges()
		if i == head.size()-1:
			checker() #Start check version
	pass 
func checker():
	state("Checking version")
	if FileAccess.file_exists("user://"+file_name): #Check if file present
		if FileAccess.file_exists("user://etag.txt"): #Check if etag file present
			state("Check etag")
			var etag = FileAccess.open("user://etag.txt", FileAccess.READ)
			if etag.get_as_text() == update_headers["Etag"]: #If bucket version is eq
				state("Launch...")
				OS.execute_with_pipe(OS.get_user_data_dir()+"/"+file_name,[]) #Run game
				get_tree().quit() #And close launcher
				pbar(0,0)
				pass
			else: #Update if version different
				update()
		else: #update if no etag file
			update()
		pass
	else: #Update if no game file
		update()
	pass
func update():
	if FileAccess.file_exists("user://"+file_name): #Check game file
		#For some reason need to write in game file empty data for redownload it.
		#It's easiest and safer than delete it
		FileAccess.open("user://"+file_name,FileAccess.WRITE).store_string("")
	$Downloader.request("https://"+host+"/"+file_name) #Send download request
	pass
func _process(delta: float) -> void:
	if $Downloader.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		$CanvasLayer/Control/Panel/LoadingState/ProgressBar.indeterminate = false
		pbar($Downloader.get_downloaded_bytes(),$Downloader.get_body_size()) #Set progressfile
		#Set text of downloaded mb and max file mb
		state("Download\n"+str($Downloader.get_downloaded_bytes()/1024/1000)+"mb / "+str($Downloader.get_body_size()/1024/1000)+"mb")
	else:
		$CanvasLayer/Control/Panel/LoadingState/ProgressBar.indeterminate = true
	pass


func _on_checker_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		state("Download complete")
		var etag_file = FileAccess.open("user://etag.txt", FileAccess.WRITE)
		if etag_file:
			etag_file.store_string(update_headers["Etag"])
			etag_file.close()
			checker() #Run checker again
		else: #If error while write etag.txt
			state("Cannot write etag")
	else:
		state("Error while download game file: ",response_code)
		
	pass # Replace with function body.


func _on_exit_pressed() -> void: #Exit button
	get_tree().quit()
	pass # Replace with function body.
