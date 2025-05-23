
ENT.Type = "anim"
ENT.Base = "base_entity"

local GizmoType = RGMGIZMOS.GizmoTypeEnum
local AxisType = RGMGIZMOS.AxisTypeEnum
local GizmoCanGimbalLock = RGMGIZMOS.CanGimbalLock

local vector_up = vector_up
local vector_front = Vector(0, 1, 0)
local vector_right = Vector(1, 0, 0)
local vector_back = -vector_front
local vector_down = -vector_up

local color_red = Color(255, 0, 0, 255)
local color_green = Color(0, 255, 0, 255)
local color_blue = Color(0, 0, 255, 255)

function ENT:Initialize()

	self.DefaultMinMax = Vector(0.1, 0.1, 0.1)
	self.LastSize = self.DefaultMinMax
	self.LastPos = self:GetPos()

	self:DrawShadow(false)
	self:SetCollisionBounds(-self.DefaultMinMax, self.DefaultMinMax)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetNotSolid(true)
	self:SetRenderMode(RENDERMODE_TRANSCOLOR)

	local CreateGizmo = RGMGIZMOS.GizmoFactory()

	-- The creation order of the gizmos below must match with `RGMGIZMOS.GizmoTable`
	self.ArrowOmni = CreateGizmo(GizmoType.OmniPos, self, Color(255, 165, 0, 255), vector_right:Angle())

	self.ArrowX = CreateGizmo(GizmoType.PosArrow, self, color_red, vector_right:Angle())
	self.ArrowY = CreateGizmo(GizmoType.PosArrow, self, color_green, vector_front:Angle())
	self.ArrowZ = CreateGizmo(GizmoType.PosArrow, self, color_blue, vector_up:Angle())

	self.ArrowXY = CreateGizmo(GizmoType.PosSide, self, color_green, vector_down:Angle(), color_red)
	self.ArrowXZ = CreateGizmo(GizmoType.PosSide, self, color_red, vector_back:Angle(), color_blue)
	self.ArrowYZ = CreateGizmo(GizmoType.PosSide, self, color_green, vector_right:Angle(), color_blue)

	self.Ball = CreateGizmo(GizmoType.Ball, self, Color(255, 255, 255, 5), vector_origin:Angle())

	self.DiscP = CreateGizmo(GizmoType.Disc, self, color_red, vector_front:Angle()) -- 0 90 0
	self.DiscP.axistype = AxisType.Pitch -- axistype is a variable to help with setting non physical bones - 1 for pitch, 2 yaw, 3 roll, 4 for the big one
	self.DiscY = CreateGizmo(GizmoType.Disc, self, color_green, vector_up:Angle()) -- 270 0 0
	self.DiscY.axistype = AxisType.Yaw
	self.DiscR = CreateGizmo(GizmoType.Disc, self, color_blue, vector_right:Angle()) -- 0 0 0
	self.DiscR.axistype = AxisType.Roll

	self.DiscLarge = CreateGizmo(GizmoType.DiscLarge, self, Color(175, 175, 175, 255), vector_right:Angle())
	self.DiscLarge.axistype = AxisType.Large

	self.ScaleX = CreateGizmo(GizmoType.ScaleArrow, self, color_red, vector_right:Angle())
	self.ScaleX.axistype = AxisType.X
	self.ScaleY = CreateGizmo(GizmoType.ScaleArrow, self, color_green, vector_front:Angle())
	self.ScaleY.axistype = AxisType.Y
	self.ScaleZ = CreateGizmo(GizmoType.ScaleArrow, self, color_blue, vector_up:Angle())
	self.ScaleZ.axistype = AxisType.Z

	self.ScaleXY = CreateGizmo(GizmoType.ScaleSide, self, color_green, vector_down:Angle(), color_red)
	self.ScaleXY.axistype = AxisType.XY
	self.ScaleXZ = CreateGizmo(GizmoType.ScaleSide, self, color_red, vector_back:Angle(), color_blue)
	self.ScaleXZ.axistype = AxisType.XZ
	self.ScaleYZ = CreateGizmo(GizmoType.ScaleSide, self, color_green, vector_right:Angle(), color_blue)
	self.ScaleYZ.axistype = AxisType.YZ

	self.Axises = {}

	for i, gizmoName in ipairs(RGMGIZMOS.GizmoTable) do
		self.Axises[i] = self[gizmoName]
	end

	if CLIENT then
		local width = GetConVar("ragdollmover_width"):GetFloat() or 0.5
		self.pwidth = width -- width var for each axis type, should take up less space than having width var for each gizmo part
		self.rwidth = width
		self.swidth = width
	end

	if CLIENT then
		self.scale = GetConVar("ragdollmover_scale"):GetFloat() or 10
	else
		local tool = self.Owner:GetTool("ragdollmover")
		if tool then
			self.scale = tool:GetClientNumber("scale", 10)
		end
	end
	self:CalculateGizmo()

	if CLIENT then
		self:SetNoDraw(true)
		self.fulldisc = GetConVar("ragdollmover_fulldisc"):GetInt() ~= 0 -- last time i used GetBool, it was breaking for 64 bit branch
	end
end

function ENT:TestCollision(pl)
	-- PrintTable(self:GetTable())
	local plTable = RAGDOLLMOVER[pl]
	local ent = plTable.Entity
	local bone = plTable.Bone
	local isparentbone = IsValid(ent) and IsValid(ent:GetParent()) and bone == 0 and not ent:IsEffectActive(EF_BONEMERGE) and not ent:IsEffectActive(EF_FOLLOWBONE) and not (ent:GetClass() == "prop_ragdoll")
	local isnonphysbone = not (isparentbone or plTable.IsPhysBone)
	local rotate = plTable.Rotate or false
	local modescale = plTable.Scale or false
	
	local start, last, inc = 1, 7, 1

	if rotate then start, last, inc = 12, 8, -1 end
	if modescale then start, last = 13, 18 end

	if not self.Axises then return false end
	for i = start, last, inc do
		local e = self.Axises[i]
		if GizmoCanGimbalLock(e.gizmotype, isnonphysbone) then continue end
		-- print(e)
		local intersect = e:TestCollision(pl)
		if intersect then return intersect end
	end

	return false
end

function ENT:CalculateGizmo()
	local scale = self.scale

	for i, axis in ipairs(self.Axises) do
		axis:CalculateGizmo(scale)
	end
end
