local facade = require"facade"
local image = require"image"
local chronos = require"chronos"

local unpack = table.unpack
local floor = math.floor

local _M = facade.driver()
setmetatable(_ENV, { __index = _M } )

local background = _M.solid_color(_M.color.white)

local function stderr(...)
    io.stderr:write(string.format(...))
end

local function test()

end

local function data(index)
	local RVGCommands = {
				fill = {
					name = 'fill',
					command = 'oddFill'
				}
			}
	local RVGForms = {}
	RVGForms['shape_type.triangle'] = {}
	RVGForms['shape_type.triangle']['name'] = 'shape_type.triangle'
	RVGForms['shape_type.triangle']['accelerate'] = 'edge'
	RVGForms['shape_type.polygon'] = {}
	RVGForms['shape_type.polygon']['name'] = 'shape_type.polygon'
	RVGForms['shape_type.polygon']['accelerate'] = 'edge'
	RVGForms['shape_type.circle'] = {}
	RVGForms['shape_type.circle']['name'] = 'shape_type.circle'
	RVGForms['shape_type.circle']['accelerate'] = 'radius'
	if index == 'RVGForms' then
		return RVGForms
	end
end

function product_vector_vector(vector1,vector2)
	result = {}
	result[1] = vector1[1]*vector2[1]
	result[2] = vector1[2]*vector2[2]
	result[3] = vector1[3]*vector2[3]
	return result
end

function product_matrix_vector(matrix,vector)
	result = {}
	result[1] = matrix[1][1] * vector[1] + matrix[1][2] * vector[2] + matrix[1][3] * vector[3]
	result[2] = matrix[2][1] * vector[1] + matrix[2][2] * vector[2] + matrix[2][3] * vector[3]
	result[3] = matrix[3][1] * vector[1] + matrix[3][2] * vector[2] + matrix[3][3] * vector[3]
	return result
end

function product_matrix_matrix(matrix1,matrix2)
	result = {}
	result[1] = {}
	result[1][1] = matrix1[1][1] * matrix2[1][1] + matrix1[1][2] * matrix2[2][1] + matrix1[1][3] * matrix2[3][1]
	result[1][2] = matrix1[1][1] * matrix2[1][2] + matrix1[1][2] * matrix2[2][2] + matrix1[1][3] * matrix2[3][2]
	result[1][3] = matrix1[1][1] * matrix2[1][3] + matrix1[1][2] * matrix2[2][3] + matrix1[1][3] * matrix2[3][3]
	result[2] = {}
	result[2][1] = matrix1[2][1] * matrix2[1][1] + matrix1[2][2] * matrix2[2][1] + matrix1[2][3] * matrix2[3][1]
	result[2][2] = matrix1[2][1] * matrix2[1][2] + matrix1[2][2] * matrix2[2][2] + matrix1[2][3] * matrix2[3][2]
	result[2][3] = matrix1[2][1] * matrix2[1][3] + matrix1[2][2] * matrix2[2][3] + matrix1[2][3] * matrix2[3][3]
	result[3] = {}
	result[3][1] = matrix1[3][1] * matrix2[1][1] + matrix1[3][2] * matrix2[2][1] + matrix1[3][3] * matrix2[3][1]
	result[3][2] = matrix1[3][1] * matrix2[1][2] + matrix1[3][2] * matrix2[2][2] + matrix1[3][3] * matrix2[3][2]
	result[3][3] = matrix1[3][1] * matrix2[1][3] + matrix1[3][2] * matrix2[2][3] + matrix1[3][3] * matrix2[3][3]
	return result
end

local function unpack8_helper(rgba, i)
	local v = rgba[i]
	if v then
		return v , unpack8_helper(rgba, i+1)
	end
end

local function unpack8(rgba)
	return unpack8_helper(rgba, 1)
end

local function sample(accelerated, x, y)
    -- This function should return the color of the sample
    -- at coordinates (x,y).
    -- Here, we simply return r = g = b = a = 1.
    -- It is up to you to compute the correct color!
    local dataRVGForms = data('RVGForms')
    local scene = accelerated
    acceleratedDataIndex = 1 
    paintColor = 0
    scene:get_scene_data():iterate{
        painted_shape = function(self, winding_rule, shape, paint)
	    local shapeType = tostring(shape:get_type())
	    local thisRVGForms = dataRVGForms[shapeType]
	    if thisRVGForms['accelerate'] == 'edge' then
		edges = acceleratedData[acceleratedDataIndex]
		acceleratedDataIndex = acceleratedDataIndex+1
		local intersections = 0
		for k,v in pairs(edges) do
			if (y > v["minY"]) and (y <= v["maxY"]) then
				local vector = v['vector']
				if vector[1] == 0 then
					intersections = intersections
				elseif vector[2] == 0 then
					local result = x + vector[3]
					if (result < 0) then
						intersections = intersections + 1
					end
				else
					local point = {x,y,1}
					local result = product_vector_vector(vector, point)
					result = result[1]+result[2]+result[3]
					if (result > 0) and (vector[1] < 0) then
						intersections = intersections + 1
					elseif (result < 0) and (vector[1] > 0) then
						intersections = intersections + 1
					end
				end
			end
		end
		if math.fmod(intersections,2) == 1 then
			paintColor = paint:get_solid_color()
		end
	    elseif thisRVGForms['accelerate'] == 'radius' then
		radius = acceleratedData[acceleratedDataIndex]
		acceleratedDataIndex = acceleratedDataIndex+1
		local result = math.pow(x-radius['center'][1],2)+math.pow(y-radius['center'][2],2)-radius['squaredRadius']
		if result < 0 then
			paintColor = paint:get_solid_color()
		end
	    end
	end
    }
    if paintColor == 0 then
    	return 1, 1, 1, 1
    else
	local r, g, b = unpack8(paintColor)
	return r, g, b, 1
    end
end

local function parse(args)
	local parsed = {
		pattern = nil,
		tx = nil,
		ty = nil,
        linewidth = nil,
		maxdepth = nil,
		p = nil,
		dumptreename = nil,
		dumpcellsprefix = nil,
	}
    local options = {
        { "^(%-tx:(%-?%d+)(.*))$", function(all, n, e)
            if not n then return false end
            assert(e == "", "trail invalid option " .. all)
            parsed.tx = assert(tonumber(n), "number invalid option " .. all)
            return true
        end },
        { "^(%-ty:(%-?%d+)(.*))$", function(all, n, e)
            if not n then return false end
            assert(e == "", "trail invalid option " .. all)
            parsed.ty = assert(tonumber(n), "number invalid option " .. all)
            return true
        end },
        { "^(%-p:(%d+)(.*))$", function(all, n, e)
            if not n then return false end
            assert(e == "", "trail invalid option " .. all)
            parsed.p = assert(tonumber(n), "number invalid option " .. all)
            return true
        end },
        { ".*", function(all)
            error("unrecognized option " .. all)
        end }
    }
    -- process options
    for i, arg in ipairs(args) do
        for j, option in ipairs(options) do
            if option[2](arg:match(option[1])) then
                break
            end
        end
    end
    return parsed
end

function newcommandprinter(command,start,stop,points)
	return function(self, ...)
		local vector = {}
		for i=start, stop do
			value = tonumber(string.format("%g",select(i, ...)))
			if i-start == 0 then
				vector[1] = value
			else
				vector[2] = value
			end
		end
		vector[3] = 1
		table.insert(points,vector)
	end
end

function path_data_to_points(points)
	return {
		begin_contour = nil,
		linear_segment = newcommandprinter("L", 3, 4, points),
		end_closed_contour = nil
	}
end

function make_edge(start, stop)
	local dx = start[1] - stop[1]
	local dy = stop[2] - start[2]
	local dd = -start[1]*dy-start[2]*dx
	local edge = {}
	local vector = {}
	if dx ~= 0 then
		vector[1] = dy/dx
		vector[2] = 1
		vector[3] = dd/dx
	else
		vector[1] = 1
		vector[2] = 0
		vector[3] = dd/dy
	end
	edge['vector'] = vector
	edge['minY'] = math.min(start[2],stop[2])
	edge['maxY'] = math.max(start[2],stop[2])
	return edge
end

function make_transformation_matrix(data)
	matrix = {}
	matrix[1] = {}
	matrix[2] = {}
	matrix[3] = {}
	matrix[1][1] = data[1]
	matrix[1][2] = data[2]
	matrix[1][3] = data[3]
	matrix[2][1] = data[4]
	matrix[2][2] = data[5]
	matrix[2][3] = data[6]
	matrix[3][1] = data[7]
	matrix[3][2] = data[8]
	matrix[3][3] = data[9]
	return matrix
end

acceleratedData = {}
sceneTransformationMatrix = {}

function _M.accelerate(scene, window, viewport, args)
    local parsed = parse(args)
    local dataRVGForms = data('RVGForms')
    stderr("parsed arguments\n")
    for i,v in pairs(parsed) do
        stderr("  -%s:%s\n", tostring(i), tostring(v))
    end
    -- This function should inspect the scene and pre-process it into a better
    -- representation, an accelerated representation, to simplify the job of
    -- sample(accelerated, x, y).
    -- Here, we simply print some info about the scene_data and return the
    -- unmodified scene.
    scene = scene:windowviewport(window, viewport)
    print(scene:get_xf())
    local xf = scene:get_xf()
    sceneTransformationMatrix = make_transformation_matrix(xf)
    stderr("scene xf %s\n", scene:get_xf())
    acceleratedDataIndex = 1 
    scene:get_scene_data():iterate{
        painted_shape = function(self, winding_rule, shape, paint)
            stderr("painted %s %s %s\n", winding_rule, shape:get_type(), paint:get_type())
            stderr("  xf s %s\n", shape:get_xf())
	    local shapeType = tostring(shape:get_type())
	    local shapeTransformationMatrix = make_transformation_matrix(shape:get_xf())
	    shapeTransformationMatrix = product_matrix_matrix(sceneTransformationMatrix,shapeTransformationMatrix)
	    local thisRVGForms = dataRVGForms[shapeType]
	    if thisRVGForms['accelerate'] == 'edge' then
		print('edge')
		local pathData = shape:as_path_data()
		print(pathData)
		local points = {}
		pathData:iterate(path_data_to_points(points))
		for k,v in pairs(points) do
			points[k] = product_matrix_vector(shapeTransformationMatrix,v)
		end
		local edges = {}
		for k,v in pairs(points) do
			if k > 1 then
				table.insert(edges, make_edge(points[k],points[k-1]))
			else
				table.insert(edges, make_edge(points[k],points[#points]))
			end
		end
		for k,v in pairs(edges) do
			local vector = v['vector']
			print("["..v["minY"].."~"..v["maxY"].."] "..vector[1].."x+"..vector[2].."y+"..vector[3].."=0")
		end
		acceleratedData[acceleratedDataIndex] = edges
		acceleratedDataIndex = acceleratedDataIndex+1
	    elseif thisRVGForms['accelerate'] == 'radius' then
		print('radius')
		local circleData = shape:get_circle_data()
		print(circleData)
		local radius = {}
		local center = {}
		center[1] = circleData:get_cx() 
		center[2] = circleData:get_cy() 
		center[3] = 1
		radius["center"] = product_matrix_vector(shapeTransformationMatrix,center)
		radius["squaredRadius"] = math.pow(circleData:get_r(),2)
		acceleratedData[acceleratedDataIndex] = radius
		acceleratedDataIndex = acceleratedDataIndex+1
	    end
        end,
    }
    -- It is up to you to do better!
    return scene
end

function _M.render(accelerated, window, viewport, file, args)
    local parsed = parse(args)
    stderr("parsed arguments\n")
    for i,v in pairs(parsed) do
        stderr("  -%s:%s\n", tostring(i), tostring(v))
    end
local time = chronos.chronos()
    -- Get viewport to compute pixel centers
    local vxmin, vymin, vxmax, vymax = unpack(viewport, 1, 4)
    local width, height = vxmax-vxmin, vymax-vymin
    assert(width > 0, "empty viewport")
    assert(height > 0, "empty viewport")
    -- Allocate output image
    local img = image.image(width, height, 4)
    -- Render
    for i = 1, height do
stderr("\r%5g%%", floor(1000*i/height)/10)
        local y = vymin+i-1.+.5
        for j = 1, width do
            local x = vxmin+j-1+.5
            img:set_pixel(j, i, sample(accelerated, x, y))
        end
    end
stderr("\n")
stderr("rendering in %.3fs\n", time:elapsed())
time:reset()
    -- Store output image
    image.png.store8(file, img)
stderr("saved in %.3fs\n", time:elapsed())
end

return _M
