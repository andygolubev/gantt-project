-- Insert a new user and get the generated id
WITH new_user AS (
    INSERT INTO users (username, email) 
    VALUES 
    ('user_' || trunc(random() * 1000)::text, 'user_' || trunc(random() * 1000)::text || '@example.com')
    RETURNING id AS user_id
),
-- Insert a new post for the created user and get the generated post id
new_post AS (
    INSERT INTO posts (user_id, title, content)
    SELECT user_id, 'Post Title ' || trunc(random() * 100)::text, 'This is a randomly generated post content.'
    FROM new_user
    RETURNING id AS post_id, user_id
)
-- Insert 10 random comments for the created post and user
INSERT INTO comments (post_id, user_id, comment_text)
SELECT new_post.post_id, new_post.user_id, 
       'This is a random comment number ' || s.i || ' with random data ' || trunc(random() * 1000)::text
FROM generate_series(1, 100) AS s(i), new_post;