-- Get group and member info
SELECT 
    g.id as group_id,
    g.name as group_name,
    gm.user_id,
    u.full_name,
    u.email
FROM groups g
JOIN group_members gm ON g.id = gm.group_id
JOIN users u ON gm.user_id = u.id
WHERE g.name = 'Miners of the Round Table';
