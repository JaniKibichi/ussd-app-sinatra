#app.rb 

require 'sinatra'
require 'sinatra/json'
require 'sinatra/activerecord'
require './AfricasTalkingGateway'
require './Models'
require 'pony'
require 'dotenv'
Dotenv.load

#Set up database
set :database_file, 'config/database.yml'


#Set up Africastalking Gateway
gateway = AfricasTalkingGateway.new(ENV['AT_API_USERNAME'], ENV['AT_API_KEY_SANDBOX'],"sandbox")

#USSD Application
post '/ussd' do	
	#1. grab POST variables
	@sessionId = params[:sessionId]
	@serviceCode = params[:serviceCode]
	@phoneNumber = params[:phoneNumber]
	@text = params[:text]

	puts "here is #{@sessionId} and #{@serviceCode} and #{@phoneNumber} and #{@text} available."
	#Store in sessions table
	session = Session.find_or_create_by(sessionId: params[:sessionId], phoneNumber:params[:phoneNumber], level: params[:level])

	#3. explode text
	if !@text.nil?	
		text = @text.split('*')
		@userResponse = text.last
	end
	#last element in the text array is the user response
	puts "The UserResponse #{@userResponse}"

	#4. Set the default level of the user
	level = 0

	#5. check users level, retain default level if none if found for this session
	currentSession = Session.where(sessionId: @sessionId).first
	if currentSession
		level = currentSession.level
	end

	#6. Create a new account
	newAccount = Account.find_or_create_by(phoneNumber: @phoneNumber)

	#7. Check if the user has a microfinance account, if yes serve the Menu
	userAvailable = Microfinance.where(phoneNumber: @phoneNumber).first

	if userAvailable && !userAvailable.name.nil? && !userAvailable.city.nil?
		#level 0 and 1 are are for basic menus, whereas others are for financial services
		if level == 0 || level == 1
			def do (@userResponse)
				case @userResponse
				when "0" || ""
					# Graduate the user to next level & serve menu
					session = Session.find_or_create_by(sessionId: @sessionId, phoneNumber:@phoneNumber, level: 1)
					if level == 0
						# This is the first request. Note how we start the response with CON
						response  = "CON Welcome to Nerd Microfinance, #{userAvailable.name}. Choose a service.\n"
						response += "1. Please call me. \n"
						response += "2. Deposit Money. \n"
						response += "3. Withdraw Money. \n"
						response += "4. Send Money. \n"	
						response += "5. Buy Airtime. \n"
						response += "6. Repay Loan. \n"																														
						response += "7. Account Balance.\n"
						#Print the response for the AT gateway
						body response
						status 200
					end
				when "1"
					if level == 1
						#The user requests to be called. Launch call.
						callFrom = "+254711082300"
						begin
							results = gateway.call(callFrom, @phoneNumber)
							puts results
						rescue AfricasTalkingGatewayException => ex
							puts 'Encountered an error: ' + ex.message
						end
						#Create response
						response = "END Please wait while we place your call. \n"
						#Print the response for the AT gateway
						body response
						status 200												
					end
				when "2"
					if level == 1
						#Ask how much for the deposit and launch Mpesa Checkout at level 9
						response  = "CON How much are you depositing?\n"
						response += "1. 19 Shillings. \n"
						response += "2. 18 Shillings. \n"
						response += "3. 17 Shillings. \n"
						#Print the response for the AT gateway
						body response
						status 200	

						#update session to level9
						updateSession = Session.where(phoneNumber:@phoneNumber, sessionId:@sessionId).first
						if updateSession
							updateSession.update(level:9)
						end					
					end
				when "3"
					if level == 1
						#Ask how much for the withdrawal and launch B2C at level 10
						response  = "CON How much are you withdrawing?\n"
						response += "1. 15 Shillings. \n"
						response += "2. 16 Shillings. \n"
						response += "3. 17 Shillings. \n"
						#Print the response for the AT gateway
						body response
						status 200	
						#update session to level10
						updateSession = Session.where(phoneNumber:@phoneNumber, sessionId:@sessionId).first
						if updateSession
							updateSession.update(level:10)
						end
					end
				when "4"
					if level == 1
						#User wants to send money to user
						response  = "CON You can only send 15 shillings.\n"
						response += "Kindly enter a valid phone number like (0722123456). \n"
						#Print the response for the AT gateway
						body response
						status 200	
					end
				when "5"
					if level == 1
						#The user wants to buy airtime, check balance first, on success send 10/-
						userAccount = Account.where(phoneNumber:@phoneNumber).first
						if userAccount.balance > 10.00
							userAccount.balance -= 10.00
							userAccount.update(balance: userAccount.balance)
							#Send Airtime::Create an array to hold all the recipients & Add recipients
							recipients = Array.new
							recipients[0] = {"phoneNumber" => @phoneNumber, "amount" => "KES 10"}							
							begin
								# results = gateway.sendAirtime(recipients)
								results = gateway.sendAirtime(recipients)
								if results
									response  = "END Please wait while we load your airtime account.\n"
									#Print the response for the AT gateway
									body response
									status 200									

							rescue AfricasTalkingGatewayException => ex
								puts 'Encountered an error: ' + ex.message
							end
						else
							response  = "END Unfortunately your balance is below 10/-.\n"
							#Print the response for the AT gateway
							body response
							status 200							
						end
					end
				when "6"
					if level ==1
						# The user wants to repay a loan, get the amount
						response  = "CON How much are you depositing for your loan repayment?\n"
						response += "4. 15 Shillings. \n"
						response += "5. 16 Shillings. \n"
						response += "6. 17 Shillings. \n"
						#Print the response for the AT gateway
						body response
						status 200	
						#update session to level12
						updateSession = Session.where(phoneNumber:@phoneNumber, sessionId:@sessionId).first
						if updateSession
							updateSession.update(level:12)
						end						
					end
				when "7"
					if level ==1
						#Find user in Microfinance Table
						MfUser=Microfinance.where(phoneNumber:@phoneNumber).first
						#Find user's account in Account table
						AcUser=Account.where(phoneNumber:@phoneNumber).first
						#Return the ministatement on ussd
						response  = "END Your account statement..\n"
						response += "Nerd Microfinance. \n"
						response += "Name: "+MfUser.name +. " \n"
						response += "City: "+MfUser.city+. " \n"
						response += "Balance: "+AcUser.balance+. " \n"
						response += "Loan: "+AcUser.loan+. " \n"						
						#Print the response for the AT gateway
						body response
						status 200	
					end
				else
					if level == 1 
						if @userResponse.length >= 10
							#This is an assumption that the user response is a phoneNumber, send B2C
							#Update the senders account and if there is a balance, send B2C
							userAccount = Account.where(phoneNumber: @phoneNumber).first	
							if userAccount.balance > 15.00
								userAccount.balance -= 15.00
								userAccount.update(balance: userAccount.balance)
								#send B2C
								# Provide the details of a mobile money recipient (create a loop for several recipients)
								recipient1= {"phoneNumber"=>@UserResponse,"currencyCode" =>"KES","amount"=> 15.00,"metadata"=> {"name"=>"Clerk","reason" => "May Salary"}}
								recipients  = [recipient1]
								begin
									#transactions = gateway.mobilePaymentB2CRequest(productName, recipients)
									transactions = gateway.mobilePaymentB2CRequest("Nerd Payments", recipients)

									if transactions #respond with USSD menu END
										response  = "END We have sent Kes 15/- to #{@userResponse}, subject to your pending balance.\n"
										#Print the response for the AT gateway
										body response
										status 200

								rescue Exception => ex
									puts "Encountered an error: " + ex.message
								end
							else
								response  = "END Unfortunately your balance is below 15/-.\n"
								#Print the response for the AT gateway
								body response
								status 200
							end							
						else
							# We could not match this
						end
						#Do Something
					end
			end
		else
			#higher levels are for finance manenos
			def do (level)
				case level
				when 9 # Allows user to deposit set amounts
					def do (@userResponse)
						case @userResponse
						when "1"
							#call scheduler and pass amount, phone
							scheduleCheckout(19, @phoneNumber)
						when "2"
							#call scheduler and pass amount, phone
							scheduleCheckout(18, @phoneNumber)							
						when "3"
							#call scheduler and pass amount, phone
							scheduleCheckout(17, @phoneNumber)							
						else
							response  = "END Sorry, something went wrong with the transaction. Please try again.\n"
							#Print the response for the AT gateway
							body response
							status 200								
					end
				when 10 # Allows user to withdraw
					def do (@userResponse)
						case @userResponse
						when "1"
							sendUserWithdrawal(15,@phoneNumber)
						when "2"
							sendUserWithdrawal(16,@phoneNumber)
						when "3"
							sendUserWithdrawal(17,@phoneNumber)
						else
							response  = "END Sorry, something went wrong with the transaction. Please try again.\n"
							#Print the response for the AT gateway
							body response
							status 200	
					end						
				when 12 # Allows user to repay loan using C2B
					def do (@userResponse)
						case @userResponse
						when "4"
							#call scheduler and pass amount, phone
							scheduleCheckout(15, @phoneNumber)
						when "5"
							#call scheduler and pass amount, phone
							scheduleCheckout(16, @phoneNumber)
						when "6"
							#call scheduler and pass amount, phone
							scheduleCheckout(17, @phoneNumber)
						else
							response  = "END Sorry, something went wrong with the transaction. Please try again.\n"
							#Print the response for the AT gateway
							body response
							status 200								
					end
				else
					response  = "END Sorry, something went wrong with the transaction. Please try again.\n"
					#Print the response for the AT gateway
					body response
					status 200						
			end
		end
	else # Complete registering the user
		#check that the user response for unregistered user is not empty
		if @userResponse == ""
			def do (level)
				case level
				when 0
					#update sessions table - graduate the user so you dont serve the same menu
					updateSession = Session.where(phoneNumber:@phoneNumber, sessionId:@sessionId).first
					if updateSession
						updateSession.update(level:1)
					end						
					#update microfinance
					MicroFUser = Microfinance.find_or_create_by(phoneNumber:@phoneNumber)					
					#response
					response  = "CON Please enter your name (e.g. Ann Other).\n"
					#Print the response for the AT gateway
					body response
					status 200						
				when 1
					#Request again for Name - level has not changed ...
					response  = "CON Name not supposed to be empty...\n"
					response += "Please enter your name (e.g. Ann Other).\n"
					#Print the response for the AT gateway
					body response
					status 200						
				when 2
					#Request again for Name - level has not changed ...
					response  = "CON City not supposed to be empty...\n"
					response += "Please enter your City (e.g. Nairobi).\n"
					#Print the response for the AT gateway
					body response
					status 200							
				else
					#something went wrong
					response  = "END Apologies, something went wrong...\n"
					#Print the response for the AT gateway
					body response
					status 200						
			end
		else
			def do (level)
				case level
				when 0
					#Graduate user so you dont serve them the same menu
					session = Session.find_or_create_by(sessionId: @sessionId, phoneNumber:@phoneNumber, level: 1)					
					#Insert Phone Number
					MicroFUser = Microfinance.find_or_create_by(phoneNumber:@phoneNumber)					
					#Serve menu request for name
					response  = "CON Please enter your name (e.g. Ann Other)...\n"
					#Print the response for the AT gateway
					body response
					status 200
				when 1
					#Update Name (Microfinance)
					updateMFUser = Microfinance.where(phoneNumber:@phoneNumber).first
					if updateMFUser
						updateMFUser.update(name:@userResponse)
					end						
					#Graduate user to city level 2 (Sessions)
					updateSession = Session.where(phoneNumber:@phoneNumber, sessionId:@sessionId).first
					if updateSession
						updateSession.update(level:2)
					end						
					#Serve menu request for city
					response  = "CON Please enter your city (e.g. Nairobi)...\n"
					#Print the response for the AT gateway
					body response
					status 200					
				when 2
					#Update City (Microfinance)
					updateMFUser = Microfinance.where(phoneNumber:@phoneNumber).first
					if updateMFUser
						updateMFUser.update(city:@userResponse)
					end						
					#Demote user level to 0
					updateSession = Session.where(phoneNumber:@phoneNumber, sessionId:@sessionId).first
					if updateSession
						updateSession.update(level:0)
					end						
					#Congratulate user and serve main menu
					response  = "CON You have successfully registered. Choose a service.\n"
					response += "1. Please call me. \n"
					response += "2. Deposit Money. \n"
					response += "3. Withdraw Money. \n"
					response += "4. Send Money. \n"	
					response += "5. Buy Airtime. \n"
					response += "6. Repay Loan. \n"																														
					response += "7. Account Balance.\n"
					#Print the response for the AT gateway
					body response
					status 200					
				else
					#something went wrong
					response  = "END Apologies, something went wrong...\n"
					#Print the response for the AT gateway
					body response
					status 200						
			end
		end
	end


	#methods
	def scheduleCheckout(amount, @phoneNumber)
		#alert user that checkout it scheduled
		response = "END Kindly wait 1 minute for the checkout. \n"
		#Print the response for the AT gateway
		body response
		status 200		
		#create record in checkout to be cleaned by cronJob
		newCheckout = Checkout.find_or_create_by(phoneNumber: @phoneNumber, status:'pending', amount: amount)
	end

	def sendUserWithdrawal(amount, @phoneNumber)
		#Update the senders account and if there is a balance, send B2C to the sender
		userAccount = Account.where(phoneNumber: @phoneNumber).first	
		if userAccount.balance > amount
			userAccount.balance -= amount
			userAccount.update(balance: userAccount.balance)
			#send B2C
			# Provide the details of a mobile money recipient (create a loop for several recipients)
			recipient1= {"phoneNumber"=>@phoneNumber,"currencyCode" =>"KES","amount"=> amount,"metadata"=> {"name"=>@phoneNumber,"reason" => "Withdrawal"}}
			recipients  = [recipient1]
			begin
				#transactions = gateway.mobilePaymentB2CRequest(productName, recipients)
				transactions = gateway.mobilePaymentB2CRequest("Nerd Payments", recipients)

				if transactions #respond with USSD menu END
					response  = "END We have sent Kes #{amount} to #{@phoneNumber}, subject to your pending balance.\n"
					#Print the response for the AT gateway
					body response
					status 200

			rescue Exception => ex
				puts "Encountered an error: " + ex.message
			end
		else
			response  = "END Unfortunately your balance is below #{amount}.\n"
			#Print the response for the AT gateway
			body response
			status 200
		end	
	end
end

#PAYMENTS Notifications
post '/notifications' do
	#1. grab POST variables
	@category = params[:category]
	@status = params[:status]
	@phoneNumber = params[:source]
	@clientAccount = params[:clientAccount]	
	@value = params[:value]	

	#2. Check the category and status
	if @category =="MobileCheckout" && @status == "Success"
		#We have been paid by one of our customers
		if @value
			kes = @value.split(" ")
			cash = kes.last
			theValue = cash.to_i
		end
		#Find Account
		userAccount = Account.where(phoneNumber:@phoneNumber).first
		if userAccount.balance 
			userAccount.balance += theValue
			userAccount.update(balance: userAccount.balance)				
		end
	elsif @category =="MobileC2B" && @status == "Success"
		#We have been paid by one of our customers
		if @value
			kes = @value.split(" ")
			cash = kes.last
			theValue = cash.to_i
		end
		#Find Account
		userAccount = Account.where(phoneNumber:@phoneNumber).first
		if userAccount.balance 
			userAccount.balance += theValue
			userAccount.update(balance: userAccount.balance)				
		end
	elsif @category =="MobileB2C" && @status == "Success"
		#We have paid someone
				#We have been paid by one of our customers
		if @value
			kes = @value.split(" ")
			cash = kes.last
			theValue = cash.to_i
		end
		#Puts the value
		puts theValue
	end

end









