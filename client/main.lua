local isDead = false

function ShowBillsMenu()
	ESX.TriggerServerCallback('esx_billing:getBills', function(bills)
		local options, totalPay = {}, 0

		if #bills > 0 then
			for k, v in ipairs(bills) do
				local y, m, d, h, i, s = string.match(v.created, '(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)')
				local month = m:gsub('%S+', {['01'] = 'January', ['02'] = 'February', ['03'] = 'March', ['04'] = 'April', ['05'] = 'May', ['06'] = 'June', ['07'] = 'July', ['08'] = 'August', ['09'] = 'September', ['10'] = 'October', ['11'] = 'November', ['12'] = 'December'})

				table.insert(options, {
					icon = 'fas fa-scroll',
					title = v.label .. ' - $' .. ESX.Math.GroupDigits(v.amount),
					onSelect = function()
						ESX.TriggerServerCallback('esx_billing:payBill', function()
							ShowBillsMenu()
						end, v.id)
					end,
					description = ('%s %s, %s (%s:%s)'):format(month, d, y, h, i),
				})
				totalPay = totalPay + v.amount
			end
		else
			table.insert(options, { title = TranslateCap('no_invoices'), disabled = true })
		end

		lib.registerContext({
			id = 'esx_billing:getBills',
			title = 'Invoices - $' .. ESX.Math.GroupDigits(totalPay),
			options = options,
		})
		lib.showContext('esx_billing:getBills')
	end)
end

RegisterNetEvent('esx_billing:ShowBillsMenu', function()
	if not isDead and lib.getOpenContextMenu() == nil then
		ShowBillsMenu()
	end
end)

AddEventHandler('esx:onPlayerDeath', function() isDead = true end)
AddEventHandler('esx:onPlayerSpawn', function(spawn) isDead = false end)
