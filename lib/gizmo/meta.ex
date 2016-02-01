defmodule Gizmo.Meta do
	defstruct [
		:size1,
		:size2,
		:crc1,
		:crc2,
		:version1,
		:version2,
		:label,
		:properties,
		:levels,
		:keyframes,
		:messages,
		:marks,
		:packages,
		:object_map,
		:names,
		:class_property_map
	]

	defmodule Property do
		defstruct [
			:type,
			:size,
			:value
		]
	end

	defmodule Keyframe do
		defstruct [
			:time,
			:frame,
			:position
		]
	end

	defmodule Message do
		defstruct [
			:frame,
			:name,
			:content
		]
	end

	defmodule Mark do
		defstruct [
			:type,
			:frame
		]
	end
end
