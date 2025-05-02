
include("shared.lua")

local VECTOR_FRONT = RGM_Constants.VECTOR_FRONT
local COLOR_RGMGREEN = RGM_Constants.COLOR_GREEN
local COLOR_RGMBLACK = RGM_Constants.COLOR_BLACK
local OUTLINE_WIDTH = RGM_Constants.OUTLINE_WIDTH
local ANGLE_ARROW_OFFSET = Angle(0, 90, 90)
local ANGLE_DISC = Angle(0, 90, 0)

local GizmoCanGimbalLock = RGMGIZMOS.CanGimbalLock
local Fulldisc = GetConVar("ragdollmover_fulldisc")
local IsValid = IsValid

local pl

function ENT:DrawLines(width)
	if not pl then pl = LocalPlayer() end

	local plTable = RAGDOLLMOVER[pl]
	local rotate = plTable.Rotate or false
	local modescale = plTable.Scale or false
	local ent = plTable.Entity
	local bone = plTable.Bone or 0
	local isparentbone = IsValid(ent) and IsValid(ent:GetParent()) and bone == 0 and not ent:IsEffectActive(EF_BONEMERGE) and not ent:IsEffectActive(EF_FOLLOWBONE) and not (ent:GetClass() == "prop_ragdoll")
	local isnonphysbone = not (isparentbone or plTable.IsPhysBone)

	local scale = self.scale
	local start, last = 1, 7
	if rotate then start, last = 8, 12 end
	if modescale then start, last = 13, 18 end

	-- First, draw all gizmos for a specific mode as unselected
	local selected = {}
	for i = start, last do
		local moveaxis = self.Axises[i]
		if GizmoCanGimbalLock(moveaxis.gizmotype, isnonphysbone) then continue end

		if moveaxis:TestCollision(pl) then
			table.insert(selected, i)
		end

		moveaxis:DrawLines(false, scale, width)
	end
	
	-- Then iterate over the selected gizmos and draw a single selected one yellow
	local gotselected = false
	local inc = 1
	start, last = 1, #selected
	if rotate then start, last, inc = #selected, 1, -1 end -- We also switched the order in `:TestCollision`, so selections are consistent
	for i = start, last, inc do
		local moveaxis = self.Axises[selected[i]]
		if selected[i] and not gotselected then
			gotselected = moveaxis.id
		end
		if moveaxis.IsBall and #selected > 1 then
			continue
		end

		if gotselected == moveaxis.id then
			moveaxis:DrawLines(gotselected == moveaxis.id, scale, width)
		end
	end

	if rotate then self.rwidth = width
	elseif modescale then self.swidth = width
	else self.pwidth = width end
end

function ENT:DrawDirectionLine(norm, ghost)
	local pos1 = self:GetPos():ToScreen()
	local pos2 = (self:GetPos() + (norm * self.scale)):ToScreen()
	local grn = 255
	if ghost then grn = 150 end
	surface.SetDrawColor(0, grn, 0, 255)
	surface.DrawLine(pos1.x, pos1.y, pos2.x, pos2.y)
end

local mabs, mround = math.abs, math.Round

function ENT:DrawAngleText(axis, hitpos, startAngle)
	local pos = WorldToLocal(hitpos, angle_zero, axis:GetPos(), axis:GetAngles())
	local overnine
	pos = WorldToLocal(pos, pos:Angle(), vector_origin, startAngle:Angle())

	local localized = Vector(pos.x, pos.z, 0):Angle()

	if(localized.y > 181) then
		overnine = 360
	else
		overnine = 0
	end

	local textAngle = mabs(mround((overnine - localized.y) * 100) / 100)
	local textpos = hitpos:ToScreen()
	draw.SimpleTextOutlined(textAngle, "RagdollMoverAngleFont", textpos.x + 5, textpos.y, COLOR_RGMGREEN, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, OUTLINE_WIDTH, COLOR_RGMBLACK)
end

function ENT:Draw()
end
function ENT:DrawTranslucent()
end

local lastang = nil

function ENT:Think()
	if not pl or not RAGDOLLMOVER[pl] then return end
	if self ~= RAGDOLLMOVER[pl].Axis then return end
	local plTable = RAGDOLLMOVER[pl]

	local ent = plTable.Entity
	if not IsValid(ent) or not plTable.Bone or not self.Axises then return end

	if not plTable.Moving then -- Prevent whole thing from rotating when we do localized rotation
		if plTable.Rotate then
			if not plTable.IsPhysBone then
				local manipang = ent:GetManipulateBoneAngles(plTable.Bone)
				if manipang ~= lastang then
					self.DiscP.LocalAng = Angle(0, 90 + manipang.y, 0) -- Pitch follows Yaw angles
					self.DiscR.LocalAng = Angle(0 + manipang.x, 0 + manipang.y, 0) -- Roll follows Pitch and Yaw angles
					lastang = manipang
				end
			else
				self.DiscP.LocalAng = ANGLE_DISC
				self.DiscR.LocalAng = angle_zero
				lastang = nil
			end
		else
			self.DiscP.LocalAng = ANGLE_DISC
			self.DiscR.LocalAng = angle_zero
			lastang = nil
		end
	end

	local plviewent = plTable.always_use_pl_view == 1 and pl or (plTable.PlViewEnt ~= 0 and Entity(plTable.PlViewEnt) or pl:GetViewEntity())
	local pos, poseye = self:GetPos(), plviewent:EyePos()

	local ang = (pos - poseye):Angle()
	ang = self:WorldToLocalAngles(ang)
	self.DiscLarge.LocalAng = ang
	self.ArrowOmni.LocalAng = ang

	pos, poseye = self:WorldToLocal(pos), self:WorldToLocal(poseye)
	local xangle, yangle = (Vector(pos.y, pos.z, 0) - Vector(poseye.y, poseye.z, 0)):Angle(), (Vector(pos.x, pos.z, 0) - Vector(poseye.x, poseye.z, 0)):Angle()
	local XAng, YAng, ZAng = Angle(0, 0, xangle.y + 90) + VECTOR_FRONT:Angle(), ANGLE_ARROW_OFFSET - Angle(0, 0, yangle.y), Angle(0, ang.y, 0) + vector_up:Angle()
	self.ArrowX.LocalAng = XAng
	self.ScaleX.LocalAng = XAng
	self.ArrowY.LocalAng = YAng
	self.ScaleY.LocalAng = YAng
	self.ArrowZ.LocalAng = ZAng
	self.ScaleZ.LocalAng = ZAng
end
