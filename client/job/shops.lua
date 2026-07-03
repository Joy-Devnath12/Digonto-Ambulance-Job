local DrawMarker            = DrawMarker
local IsControlJustReleased = IsControlJustReleased
local CreateThread          = CreateThread

function initPharmacyPeds(hospital)
    for name, pharmacy in pairs(hospital.pharmacy) do
        if pharmacy.model and pharmacy.pos then
            local ped = utils.createPed(pharmacy.model, pharmacy.pos)
            if ped then
                FreezeEntityPosition(ped, true)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)

                addLocalEntity(ped, {
                    {
                        label = pharmacy.label or "Pharmacy",
                        icon = 'fa-solid fa-store',
                        groups = pharmacy.job and Config.EmsJobs or false,
                        fn = function()
                            inv.openShop(name)
                        end
                    }
                })
            end
        end
    end
end

local function createShops()
    for _, hospital in pairs(Config.Hospitals) do
        for name, pharmacy in pairs(hospital.pharmacy) do
            if pharmacy.blip and pharmacy.blip.enable then
                local blipData = {
                    enable = pharmacy.blip.enable,
                    name = pharmacy.blip.name,
                    type = pharmacy.blip.type,
                    scale = pharmacy.blip.scale,
                    color = pharmacy.blip.color,
                    pos = pharmacy.blip.pos or (type(pharmacy.pos) == 'vector4' and pharmacy.pos.xyz or pharmacy.pos)
                }
                utils.createBlip(blipData)
            end

            if not pharmacy.model then
                lib.points.new({
                    coords = pharmacy.pos,
                    distance = 3,
                    onEnter = function(self)
                        if pharmacy.job then
                            if hasJob(Config.EmsJobs) and getPlayerJobGrade() >= pharmacy.grade then
                                self.access = true
                                lib.showTextUI(locale('control_to_open_shop'))
                            else
                                self.access = false
                            end
                        else
                            self.access = true
                            lib.showTextUI(locale('control_to_open_shop'))
                        end
                    end,
                    onExit = function()
                        lib.hideTextUI()
                    end,
                    nearby = function(self)
                        if self.access then
                            DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.0, 1.0, 1.0, 200, 20, 20, 50, false, true, 2, false, nil, nil, false)

                            if self.currentDistance < 1 and IsControlJustReleased(0, 38) then
                                inv.openShop(name)
                            end
                        end
                    end
                })
            end
        end
    end
end
CreateThread(createShops)

