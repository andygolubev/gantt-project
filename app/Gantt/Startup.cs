using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Npgsql;
using Microsoft.AspNetCore.Http;
using Dapper;
using System.Data;
using System.Threading.Tasks;

public class Startup
{
    public IConfiguration Configuration { get; }

    public Startup(IConfiguration configuration)
    {
        Configuration = configuration;
    }

    public void ConfigureServices(IServiceCollection services)
    {
        services.AddControllers();
        services.AddSingleton<IDbConnection>(sp =>
            new NpgsqlConnection(Configuration.GetConnectionString("DefaultConnection")));
    }

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        if (env.IsDevelopment())
        {
            app.UseDeveloperExceptionPage();
        }

        app.UseRouting();

        app.UseEndpoints(endpoints =>
        {
            endpoints.MapGet("/", async context =>
            {
                await context.Response.WriteAsync("Healthy");
            });

            endpoints.MapGet("/read", async context =>
            {
                var connection = context.RequestServices.GetRequiredService<IDbConnection>();
                var sql = @"SELECT 
                            users.id AS user_id,
                            users.username,
                            users.email,
                            COALESCE(post_count, 0) AS total_posts,
                            COALESCE(comment_count, 0) AS total_comments,
                            COALESCE(post_count, 0) + COALESCE(comment_count, 0) AS total_activity
                        FROM 
                            users
                        LEFT JOIN 
                            (SELECT user_id, COUNT(*) AS post_count FROM posts GROUP BY user_id) AS user_posts
                            ON users.id = user_posts.user_id
                        LEFT JOIN 
                            (SELECT user_id, COUNT(*) AS comment_count FROM comments GROUP BY user_id) AS user_comments
                            ON users.id = user_comments.user_id
                        ORDER BY 
                            total_activity DESC
                        LIMIT 50;";
                
                var result = await connection.QueryAsync(sql);
                await context.Response.WriteAsJsonAsync(result);
            });

            endpoints.MapPost("/write", async context =>
            {
                var connection = context.RequestServices.GetRequiredService<IDbConnection>();
                
                var sql = @"
                    WITH new_user AS (
                        INSERT INTO users (username, email) 
                        VALUES 
                        ('user_' || trunc(random() * 1000)::text, 'user_' || trunc(random() * 1000)::text || '@example.com')
                        RETURNING id AS user_id
                    ),
                    new_post AS (
                        INSERT INTO posts (user_id, title, content)
                        SELECT user_id, 'Post Title ' || trunc(random() * 100)::text, 'This is a randomly generated post content.'
                        FROM new_user
                        RETURNING id AS post_id, user_id
                    )
                    INSERT INTO comments (post_id, user_id, comment_text)
                    SELECT new_post.post_id, new_post.user_id, 
                        'This is a random comment number ' || s.i || ' with random data ' || trunc(random() * 1000)::text
                    FROM generate_series(1, 10) AS s(i), new_post;"; // Adjusted to insert 10 comments

                try
                {
                    var result = await connection.ExecuteAsync(sql);
                    await context.Response.WriteAsync("Data Inserted Successfully");
                }
                catch (Exception ex)
                {
                    context.Response.StatusCode = 500; // Internal Server Error
                    await context.Response.WriteAsync($"An error occurred: {ex.Message}");
                }
            });
        });
    }
}
