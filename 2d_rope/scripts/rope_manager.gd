@tool
extends Node2D
class_name RopeManager

@export_category("GENERATOR")
@export var generate_shape : bool = false : set=_set_generate_shape
@export var clear_shapes : bool = false : set = _clear_children
@export_category("Rope start setting")
@export var start_body_preset : PackedScene
@export_category("Rope settings")
@export var rigid_body_preset : PackedScene
@export var joint_preset : PackedScene
@export var resolution : int 
@export var joint_margin : float

@export_category("Rope end settings")
@export var has_end_node : bool = false
@export var end_point : PackedScene

var child_container : Array

func _clear_children(new_value)->void:
	clear_shapes = false
	clear_rope_container()

func _set_generate_shape(new_value:bool)->void:
	if !Engine.is_editor_hint():
		return
	generate_shape = false
	child_container = []
	clear_rope_container()
	generate_segments()
	child_container = get_children()
	update_joint_segments()
	
func update_joint_segments()->void:
	for i in child_container.size()-1:
		var child = child_container[i]
		if child is PhysicsBody2D:
			continue
		set_joint_segment_neightbors(child,i-1,i+1)

func clear_rope_container()->void:
	for i in get_children():
		i.queue_free()

func generate_rigid_body()->void:
	var instance = rigid_body_preset.instantiate()
	
	add_child(instance,true)
	instance.owner = get_tree().edited_scene_root
	
	var instance_sprite = (instance.get_child(0) as Sprite2D)
	var insntace_spawn_point = (instance_sprite.texture.get_size()-Vector2(instance_sprite.texture.get_size().x,0.0))*0.5*instance_sprite.scale
	instance.global_position =  insntace_spawn_point + Vector2(global_position.x,child_container.back().global_position.y- joint_margin*0.5) 
	child_container.append(instance)
	

func generate_joint()->void:
	var instance = joint_preset.instantiate()
	
	add_child(instance,true)
	instance.owner = get_tree().edited_scene_root
	
	var instance_sprite = child_container.back().get_child(0)
	
	#var insntace_spawn_point = (instance_sprite.texture.get_size()-Vector2(instance_sprite.texture.get_size().x,-joint_margin))*0.5*instance_sprite.scale
	instance.global_position =  Vector2(global_position.x,instance_sprite.global_position.y-( (instance_sprite as Sprite2D).get_rect().size.y * 0.75) - joint_margin*0.5)
	
	child_container.append(instance)
	

func generate_start_segment()->void:
	var instance = start_body_preset.instantiate()
	
	add_child(instance,true)
	instance.owner = get_tree().edited_scene_root
	
	var instance_sprite = (instance.get_child(0) as Sprite2D)
	var insntace_spawn_point = (instance_sprite.texture.get_size()-Vector2(instance_sprite.texture.get_size().x,0.0))*0.5*instance_sprite.scale
	instance.global_position = global_position - insntace_spawn_point
	
	child_container.append(instance)
	
	
func generate_end_segment()->void:
	if !has_end_node:
		if get_child_count() == 1:
			return
		var last_node = child_container.pop_back()
		
		if last_node == null:
			return
		
		if is_instance_of(last_node,PhysicsBody2D):
			return
		
		last_node.queue_free()
		return
	

func generate_segments()->void:
	generate_start_segment()
	for i in resolution:
		generate_joint()
		generate_rigid_body()
	
	generate_end_segment()

func set_joint_segment_neightbors(joint:PinJoint2D,segment_a,segment_b)->void:
	if segment_a is PinJoint2D:
		return
	
	if segment_b is PinJoint2D:
		return
	
	joint.node_a = child_container[segment_a].get_path()
	joint.node_b = child_container[segment_b].get_path()
	
