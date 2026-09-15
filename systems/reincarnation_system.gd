class_name ReincarnationSystem
extends RefCounted

const REALM_REWARDS := {
	0: {"luck": 0, "physique": 0, "comprehension": 1},
	1: {"luck": 1, "physique": 0, "comprehension": 1},
	2: {"luck": 1, "physique": 1, "comprehension": 1},
	3: {"luck": 2, "physique": 1, "comprehension": 2},
	4: {"luck": 2, "physique": 2, "comprehension": 2},
	5: {"luck": 3, "physique": 2, "comprehension": 3},
	6: {"luck": 3, "physique": 3, "comprehension": 3},
	7: {"luck": 4, "physique": 3, "comprehension": 4},
	8: {"luck": 5, "physique": 5, "comprehension": 5}
}

static func calculate_meta_reward(realm: int, level: int) -> Dictionary:
	var reward: Dictionary = REALM_REWARDS.get(realm, REALM_REWARDS[0]).duplicate()
	var level_bonus := int(level / 4)
	reward["comprehension"] += level_bonus
	if level >= 8:
		reward["luck"] += 1
	return reward

static func apply_reward(meta: Dictionary, reward: Dictionary) -> Dictionary:
	var result := meta.duplicate()
	result["luck"] = int(result.get("luck", 0)) + int(reward.get("luck", 0))
	result["physique"] = int(result.get("physique", 0)) + int(reward.get("physique", 0))
	result["comprehension"] = int(result.get("comprehension", 0)) + int(reward.get("comprehension", 0))
	return result

static func get_life_title(reincarnations: int) -> String:
	if reincarnations == 0:
		return "凡人初世"
	if reincarnations < 3:
		return "初窥轮回"
	if reincarnations < 10:
		return "轮回行者"
	if reincarnations < 25:
		return "百世求道"
	return "万劫归一"
