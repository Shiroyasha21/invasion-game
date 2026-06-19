class_name UpgradeCard
extends RefCounted

enum Kind { GLOBAL_STAT, TOWER_ATTACHMENT, RARE }

var id: String
var title: String
var description: String
var kind: int
var tower_id: String = ""  # "" means it applies to every tower
var stat: String = ""  # "damage", "range", "fire_rate", "splash"
var amount: float = 0.0
var rare_data: RareAttachmentData = null


static func make_stat(id: String, title: String, description: String, kind: int, tower_id: String, stat: String, amount: float) -> UpgradeCard:
	var c := UpgradeCard.new()
	c.id = id
	c.title = title
	c.description = description
	c.kind = kind
	c.tower_id = tower_id
	c.stat = stat
	c.amount = amount
	return c


static func make_rare(rare_data: RareAttachmentData) -> UpgradeCard:
	var c := UpgradeCard.new()
	c.id = "rare_%s" % rare_data.id
	c.title = rare_data.title
	c.description = rare_data.description
	c.kind = Kind.RARE
	c.rare_data = rare_data
	return c
