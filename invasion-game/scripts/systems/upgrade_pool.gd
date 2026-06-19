class_name UpgradePool
extends RefCounted

# Central list of every possible level-up card. Add a new entry here to add
# a new upgrade to the game — no other code needs to change.

const RARE_PATHS := [
	"res://resources/rare_attachments/overcharged.tres",
	"res://resources/rare_attachments/hawkeye.tres",
]


static func all_cards() -> Array[UpgradeCard]:
	var cards: Array[UpgradeCard] = []

	# Global stat boosts — apply to every tower on the field.
	cards.append(UpgradeCard.make_stat("global_damage", "Sharpened Arsenal", "+15% damage, all towers", UpgradeCard.Kind.GLOBAL_STAT, "", "damage", 0.15))
	cards.append(UpgradeCard.make_stat("global_range", "Eagle Eye", "+15% range, all towers", UpgradeCard.Kind.GLOBAL_STAT, "", "range", 0.15))
	cards.append(UpgradeCard.make_stat("global_fire_rate", "Quickened Reflexes", "+15% fire rate, all towers", UpgradeCard.Kind.GLOBAL_STAT, "", "fire_rate", 0.15))

	# Tower-specific attachments — flavor text differs by tower identity.
	cards.append(UpgradeCard.make_stat("arrow_multishot", "Arrow: Rapid Fire", "+25% fire rate on Arrow Towers", UpgradeCard.Kind.TOWER_ATTACHMENT, "arrow", "fire_rate", 0.25))
	cards.append(UpgradeCard.make_stat("arrow_barbs", "Arrow: Barbed Tips", "+20% damage on Arrow Towers", UpgradeCard.Kind.TOWER_ATTACHMENT, "arrow", "damage", 0.20))
	cards.append(UpgradeCard.make_stat("cannon_blast", "Cannon: Bigger Blast", "+40% splash radius on Cannons", UpgradeCard.Kind.TOWER_ATTACHMENT, "cannon", "splash", 0.40))
	cards.append(UpgradeCard.make_stat("cannon_payload", "Cannon: Heavy Payload", "+25% damage on Cannons", UpgradeCard.Kind.TOWER_ATTACHMENT, "cannon", "damage", 0.25))
	cards.append(UpgradeCard.make_stat("sniper_scope", "Sniper: Long Scope", "+30% range on Snipers", UpgradeCard.Kind.TOWER_ATTACHMENT, "sniper", "range", 0.30))
	cards.append(UpgradeCard.make_stat("sniper_rounds", "Sniper: Armor-Piercing Rounds", "+30% damage on Snipers", UpgradeCard.Kind.TOWER_ATTACHMENT, "sniper", "damage", 0.30))

	# Rare single-tower attachments — applied by tapping a tower after pick.
	for path in RARE_PATHS:
		var data: RareAttachmentData = load(path)
		cards.append(UpgradeCard.make_rare(data))

	return cards


# Picks `count` random cards, weighting rares much lower than common upgrades.
static func draw(count: int) -> Array[UpgradeCard]:
	var pool := all_cards()
	var weighted: Array[UpgradeCard] = []
	for card in pool:
		var weight := 1 if card.kind == UpgradeCard.Kind.RARE else 6
		for _i in weight:
			weighted.append(card)

	var picks: Array[UpgradeCard] = []
	var used_ids: Array[String] = []
	var attempts := 0
	while picks.size() < count and attempts < 50:
		attempts += 1
		var card: UpgradeCard = weighted[randi() % weighted.size()]
		if card.id in used_ids:
			continue
		used_ids.append(card.id)
		picks.append(card)
	return picks
