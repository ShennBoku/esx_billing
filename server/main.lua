RegisterServerEvent('esx_billing:sendBill')
AddEventHandler('esx_billing:sendBill', function(playerId, sharedAccountName, label, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	local xTarget = ESX.GetPlayerFromId(playerId)
	amount = ESX.Math.Round(amount)

	if amount > 0 and xTarget then
		TriggerEvent('esx_addonaccount:getSharedAccount', sharedAccountName, function(account)
			if account then
				MySQL.insert('INSERT INTO billing (identifier, sender, target_type, target, label, amount) VALUES (?, ?, ?, ?, ?, ?)', {xTarget.identifier, xPlayer.identifier, 'society', sharedAccountName, label, amount},
				function(rowsChanged)
					if string.upper(Config.Notification.res) == 'OKOK' and GetResourceState('okokNotify') ~= 'missing' then
						local ndt = Config.Notification.data.okok
						TriggerClientEvent('okokNotify:Alert', xTarget.playerId, ndt.title, TranslateCap('received_invoice'), ndt.time, ndt.type)
					else
						xTarget.showNotification(TranslateCap('received_invoice'))
					end
				end)
			else
				MySQL.insert('INSERT INTO billing (identifier, sender, target_type, target, label, amount) VALUES (?, ?, ?, ?, ?, ?)', {xTarget.identifier, xPlayer.identifier, 'player', xPlayer.identifier, label, amount},
				function(rowsChanged)
					if string.upper(Config.Notification.res) == 'OKOK' and GetResourceState('okokNotify') ~= 'missing' then
						local ndt = Config.Notification.data.okok
						TriggerClientEvent('okokNotify:Alert', xTarget.playerId, ndt.title, TranslateCap('received_invoice'), ndt.time, ndt.type)
					else
						xTarget.showNotification(TranslateCap('received_invoice'))
					end
				end)
			end
		end)
	end
end)

ESX.RegisterServerCallback('esx_billing:getBills', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.query("SELECT amount, id, label, DATE_FORMAT(created, '%Y-%m-%d %H:%i:%s') AS created FROM billing WHERE identifier = ?", {xPlayer.identifier},
	function(result)
		cb(result)
	end)
end)

ESX.RegisterServerCallback('esx_billing:getTargetBills', function(source, cb, target)
	local xPlayer = ESX.GetPlayerFromId(target)

	if xPlayer then
		MySQL.query("SELECT amount, id, label, DATE_FORMAT(created, '%Y-%m-%d %H:%i:%s') AS created FROM billing WHERE identifier = ?", {xPlayer.identifier},
		function(result)
			cb(result)
		end)
	else
		cb({})
	end
end)

ESX.RegisterServerCallback('esx_billing:payBill', function(source, cb, billId)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.single('SELECT sender, target_type, target, amount FROM billing WHERE id = ?', {billId},
	function(result)
		if result then
			local amount = result.amount
			local xTarget = ESX.GetPlayerFromIdentifier(result.sender)

			if result.target_type == 'player' then
				if xTarget then
					if xPlayer.getMoney() >= amount then
						MySQL.update('DELETE FROM billing WHERE id = ?', {billId},
						function(rowsChanged)
							if rowsChanged == 1 then
								xPlayer.removeMoney(amount, "Bill Paid")
								xTarget.addMoney(amount, "Paid bill")

								if string.upper(Config.Notification.res) == 'OKOK' and GetResourceState('okokNotify') ~= 'missing' then
									local ndt = Config.Notification.data.okok
									TriggerClientEvent('okokNotify:Alert', xPlayer.playerId, ndt.title, TranslateCap('paid_invoice', ESX.Math.GroupDigits(amount)), ndt.time, ndt.type)
									TriggerClientEvent('okokNotify:Alert', xTarget.playerId, ndt.title, TranslateCap('received_payment', ESX.Math.GroupDigits(amount)), ndt.time, ndt.type)
								else
									xPlayer.showNotification(TranslateCap('paid_invoice', ESX.Math.GroupDigits(amount)))
									xTarget.showNotification(TranslateCap('received_payment', ESX.Math.GroupDigits(amount)))
								end
							end

							cb()
						end)
					elseif xPlayer.getAccount('bank').money >= amount then
						MySQL.update('DELETE FROM billing WHERE id = ?', {billId},
						function(rowsChanged)
							if rowsChanged == 1 then
								xPlayer.removeAccountMoney('bank', amount, "Bill Paid")
								xTarget.addAccountMoney('bank', amount, "Paid bill")

								if string.upper(Config.Notification.res) == 'OKOK' and GetResourceState('okokNotify') ~= 'missing' then
									local ndt = Config.Notification.data.okok
									TriggerClientEvent('okokNotify:Alert', xPlayer.playerId, ndt.title, TranslateCap('paid_invoice', ESX.Math.GroupDigits(amount)), ndt.time, ndt.type)
									TriggerClientEvent('okokNotify:Alert', xTarget.playerId, ndt.title, TranslateCap('received_payment', ESX.Math.GroupDigits(amount)), ndt.time, ndt.type)
								else
									xPlayer.showNotification(TranslateCap('paid_invoice', ESX.Math.GroupDigits(amount)))
									xTarget.showNotification(TranslateCap('received_payment', ESX.Math.GroupDigits(amount)))
								end
							end

							cb()
						end)
					else
						if string.upper(Config.Notification.res) == 'OKOK' and GetResourceState('okokNotify') ~= 'missing' then
							local ndt = Config.Notification.data.okok
							TriggerClientEvent('okokNotify:Alert', xPlayer.playerId, ndt.title, TranslateCap('no_money'), ndt.time, ndt.type)
							TriggerClientEvent('okokNotify:Alert', xTarget.playerId, ndt.title, TranslateCap('target_no_money'), ndt.time, ndt.type)
						else
							xTarget.showNotification(TranslateCap('target_no_money'))
							xPlayer.showNotification(TranslateCap('no_money'))
						end
						cb()
					end
				else
					if string.upper(Config.Notification.res) == 'OKOK' and GetResourceState('okokNotify') ~= 'missing' then
						local ndt = Config.Notification.data.okok
						TriggerClientEvent('okokNotify:Alert', xPlayer.playerId, ndt.title, TranslateCap('player_not_online'), ndt.time, ndt.type)
					else
						xPlayer.showNotification(TranslateCap('player_not_online'))
					end
					cb()
				end
			else
				TriggerEvent('esx_addonaccount:getSharedAccount', result.target, function(account)
					if xPlayer.getMoney() >= amount then
						MySQL.update('DELETE FROM billing WHERE id = ?', {billId},
						function(rowsChanged)
							if rowsChanged == 1 then
								xPlayer.removeMoney(amount, "Bill Paid")
								account.addMoney(amount)

								if string.upper(Config.Notification.res) == 'OKOK' and GetResourceState('okokNotify') ~= 'missing' then
									local ndt = Config.Notification.data.okok
									TriggerClientEvent('okokNotify:Alert', xPlayer.playerId, ndt.title, TranslateCap('player_not_online'), ndt.time, ndt.type)
									if xTarget then
										TriggerClientEvent('okokNotify:Alert', xTarget.playerId, ndt.title, TranslateCap('received_payment', ESX.Math.GroupDigits(amount)), ndt.time, ndt.type)
									end
								else
									xPlayer.showNotification(TranslateCap('paid_invoice', ESX.Math.GroupDigits(amount)))
									if xTarget then
										xTarget.showNotification(TranslateCap('received_payment', ESX.Math.GroupDigits(amount)))
									end
								end
							end

							cb()
						end)
					elseif xPlayer.getAccount('bank').money >= amount then
						MySQL.update('DELETE FROM billing WHERE id = ?', {billId},
						function(rowsChanged)
							if rowsChanged == 1 then
								xPlayer.removeAccountMoney('bank', amount, "Bill Paid")
								account.addMoney(amount)

								if string.upper(Config.Notification.res) == 'OKOK' and GetResourceState('okokNotify') ~= 'missing' then
									local ndt = Config.Notification.data.okok
									TriggerClientEvent('okokNotify:Alert', xPlayer.playerId, ndt.title, TranslateCap('paid_invoice', ESX.Math.GroupDigits(amount)), ndt.time, ndt.type)
									if xTarget then
										TriggerClientEvent('okokNotify:Alert', xTarget.playerId, ndt.title, TranslateCap('received_payment', ESX.Math.GroupDigits(amount)), ndt.time, ndt.type)
									end
								else
									xPlayer.showNotification(TranslateCap('paid_invoice', ESX.Math.GroupDigits(amount)))
									if xTarget then
										xTarget.showNotification(TranslateCap('received_payment', ESX.Math.GroupDigits(amount)))
									end
								end
							end

							cb()
						end)
					else
						if xTarget then
							if string.upper(Config.Notification.res) == 'OKOK' and GetResourceState('okokNotify') ~= 'missing' then
								local ndt = Config.Notification.data.okok
								TriggerClientEvent('okokNotify:Alert', xTarget.playerId, ndt.title, TranslateCap('target_no_money'), ndt.time, ndt.type)
							else
								xTarget.showNotification(TranslateCap('target_no_money'))
							end
						end

						if string.upper(Config.Notification.res) == 'OKOK' and GetResourceState('okokNotify') ~= 'missing' then
							local ndt = Config.Notification.data.okok
							TriggerClientEvent('okokNotify:Alert', xPlayer.playerId, ndt.title, TranslateCap('no_money'), ndt.time, ndt.type)
						else
							xPlayer.showNotification(TranslateCap('no_money'))
						end

						cb()
					end
				end)
			end
		end
	end)
end)

lib.addCommand(false, 'showbills', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.triggerEvent('esx_billing:ShowBillsMenu')
end, {})