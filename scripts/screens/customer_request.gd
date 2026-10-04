extends Control

signal navigate(screen_name: String)

var _portrait_frame: Control


func _ready() -> void:
	var job: JobData = GameState.get_current_job()
	var body := ScreenUI.create_page(
		self, 1, "CUSTOMER REQUEST", job.use_case,
		"Help %s choose the right components." % job.name
	)
	var request := ScreenUI.card(body, "")
	var identity := HBoxContainer.new()
	identity.name = "CustomerIdentityRow"
	identity.add_theme_constant_override("separation", 16)
	request.add_child(identity)
	# A fixed frame keeps the large portrait from determining the page width.
	if job.id == "study":
		_portrait_frame = Control.new()
		_portrait_frame.name = "PortraitFrame"
		_portrait_frame.clip_contents = true
		_portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		identity.add_child(_portrait_frame)
		var portrait := ArtAssets.texture_rect(ArtAssets.MIKA, Vector2.ZERO)
		portrait.name = "MikaPortrait"
		_portrait_frame.add_child(portrait)
		portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_resize_portrait()
		resized.connect(_resize_portrait)
		UiMotion.fade_slide(portrait)

	var details := VBoxContainer.new()
	details.name = "CustomerDetails"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 8)
	identity.add_child(details)
	details.add_child(ScreenUI.label(GameState.customer_name, 28))
	details.add_child(ScreenUI.badge("STUDENT" if job.id == "study" else job.use_case.to_upper(), ScreenUI.BLUE))
	details.add_child(ScreenUI.label("Budget", 18, ScreenUI.MUTED))
	details.add_child(ScreenUI.label("%s coins" % ScreenUI.money(GameState.customer_budget), 24, ScreenUI.ACCENT))
	request.add_child(ScreenUI.label(job.personality, 18, ScreenUI.MUTED))
	request.add_child(ScreenUI.label(GameState.customer_request, 20))
	request.add_child(ScreenUI.label("Reward on success", 18, ScreenUI.MUTED))
	request.add_child(ScreenUI.label("+%s coins  ·  +%s XP" % [ScreenUI.money(GameState.reward_coins), ScreenUI.money(GameState.reward_xp)], 20, ScreenUI.WARNING))
	var gems: int = 0 if GameState.completed_jobs.has(job.id) else GameState.reward_gems
	if gems > 0:
		request.add_child(ScreenUI.label("+%d %s for first completion" % [gems, "gem" if gems == 1 else "gems"], 18, ScreenUI.WARNING))
	else:
		request.add_child(ScreenUI.label("First-completion gem already collected.", 18, ScreenUI.MUTED))
	UiMotion.fade_in(request.get_parent() as Control)

	var requirements := ScreenUI.card(body, "Your build checklist")
	requirements.add_child(ScreenUI.label("CPU socket and RAM type match the motherboard.", 20))
	requirements.add_child(ScreenUI.label("The motherboard supports the SSD interface.", 20))
	requirements.add_child(ScreenUI.label("The PSU covers the whole PC's power demand.", 20))
	requirements.add_child(ScreenUI.label("All five parts stay within the budget.", 20))
	requirements.add_child(ScreenUI.label(GameState.requirement_text(), 20, ScreenUI.BLUE))
	requirements.add_child(ScreenUI.label("Choose a CPU, motherboard, RAM, SSD and PSU. The provided case and cooling use 30 W.", 18, ScreenUI.MUTED))

	var actions := ScreenUI.actions(body)
	var accept_button := ScreenUI.button("Accept job", true)
	accept_button.name = "AcceptButton"
	accept_button.pressed.connect(_open_shop)
	actions.add_child(accept_button)
	var menu_button := ScreenUI.button("Back to menu")
	menu_button.name = "MenuButton"
	menu_button.pressed.connect(_open_menu)
	actions.add_child(menu_button)


func _resize_portrait() -> void:
	_portrait_frame.custom_minimum_size = Vector2(96, 128) if ScreenUI.is_compact(self) else Vector2(120, 160)


func _open_shop() -> void:
	navigate.emit("parts_shop")


func _open_menu() -> void:
	navigate.emit("main_menu")
