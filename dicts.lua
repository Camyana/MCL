-- * -----------------------------------------
-- * Set structure for frames to be stored in.
-- * This is purely for reference.
-- * -----------------------------------------

local MCL_mount_data = {
    frame: frame,
    category: category,
    expansion: expansion,
    mount_id: mount_id,
    mount_item_id: mount_item_id,

}

local MCL_expansion_data = {
    frame: frame,
    name: expansion,
    categories: categories,
    mount_ids: mounts,
    mount_item_ids: mounts,
    collected: total,

}

local MCL_category_data = {
    frame: frame,
    name: category,
    expansion: expansion,
    mount_ids: mounts,
    mount_item_ids: mounts,
    collected: total,

}