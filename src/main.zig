const std = @import("std");
const gl = @import("zgl");
const Instance = @import("./glfw/instance.zig").Instance;
const Allocator = std.mem.Allocator;

const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

fn keyCallback(
    window: ?*c.GLFWwindow,
    key: c_int,
    _: c_int,
    action: c_int,
    _: c_int,
) callconv(.c) void {
    if (key == c.GLFW_KEY_ESCAPE and action == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
    }
}

fn loadProc(comptime _: type, symbolName: [:0]const u8) ?*const anyopaque {
    return c.glfwGetProcAddress(symbolName);
}

const GLErrors = error{ FailedToCompileVertex, FailedToCompileFragment, FailedToCreateProgram };

fn createProgram(allocator: Allocator) !gl.Program {
    const program = gl.createProgram();

    const vertex_file = try std.fs.cwd().openFile("shaders/vertex.glsl", .{});
    const vertex_file_metadata = try vertex_file.metadata();
    const vertex_buffer = try vertex_file.readToEndAlloc(allocator, vertex_file_metadata.size());
    defer allocator.free(vertex_buffer);
    const vertex_shader = gl.createShader(gl.ShaderType.vertex);
    defer vertex_shader.delete();
    vertex_shader.source(1, &vertex_buffer);
    vertex_shader.compile();
    if (vertex_shader.get(gl.ShaderParameter.compile_status) == 0) {
        const status = try vertex_shader.getCompileLog(allocator);
        std.log.err("Failed to compile vertex shader: {s}", .{status});
        return GLErrors.FailedToCompileVertex;
    }

    const fragment_file = try std.fs.cwd().openFile("shaders/fragment.glsl", .{});
    const fragment_file_metadata = try fragment_file.metadata();
    const fragment_buffer = try fragment_file.readToEndAlloc(allocator, fragment_file_metadata.size());
    defer allocator.free(fragment_buffer);
    const fragment_shader = gl.createShader(gl.ShaderType.fragment);
    defer fragment_shader.delete();
    fragment_shader.source(1, &fragment_buffer);
    fragment_shader.compile();
    if (fragment_shader.get(gl.ShaderParameter.compile_status) == 0) {
        const status = try fragment_shader.getCompileLog(allocator);
        std.log.err("Failed to compile fragment shader: {s}", .{status});
        return GLErrors.FailedToCompileFragment;
    }

    program.attach(vertex_shader);
    program.attach(fragment_shader);
    program.link();
    if (program.get(gl.ProgramParameter.link_status) == 0) {
        const status = try program.getCompileLog(allocator);
        std.log.err("Failed to link shaders: {s}", .{status});
        return GLErrors.FailedToCreateProgram;
    }

    return program;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const instance = Instance.init(480, 480, "Hello world floating");
    defer instance.deinit();
    _ = c.glfwSetKeyCallback(instance.window, keyCallback);

    //c.glfwMakeContextCurrent(window);
    instance.makeCurrent();
    gl.loadExtensions(void, loadProc) catch |err| {
        std.log.err("Failed to load gl extensions {any}", .{err});
    };

    gl.viewport(0, 0, 480, 480);
    const vertices: [12]f32 = .{
        0.5,  0.5,  0.0,
        0.5,  -0.5, 0.0,
        -0.5, -0.5, 0.0,
        -0.5, 0.5,  0.0,
    };
    const indices: [6]u32 = .{ 0, 1, 3, 1, 2, 3 };

    const vao = gl.genVertexArray();
    const ebo = gl.genBuffer();

    vao.bind();
    const vbo = gl.genBuffer();
    vbo.bind(gl.BufferTarget.array_buffer);
    vbo.data(f32, &vertices, gl.BufferUsage.static_draw);
    gl.vertexAttribPointer(0, 3, gl.Type.float, false, 3 * @sizeOf(f32), 0);
    gl.enableVertexAttribArray(0);

    ebo.bind(gl.BufferTarget.element_array_buffer);
    ebo.data(u32, &indices, gl.BufferUsage.static_draw);

    const program = createProgram(arena.allocator()) catch |err| {
        std.log.err("Failed to create shader program: {any}", .{err});
        return;
    };
    program.use();

    while (c.glfwWindowShouldClose(instance.window) != c.GL_TRUE) {
        //c.glClearColor(0.2, 0.5, 0.2, 0.0);
        gl.clearColor(0.2, 0.5, 0.2, 0.0);
        gl.clear(.{ .color = true });

        //gl.drawArrays(gl.PrimitiveType.triangles, 0, 3);
        gl.drawElements(gl.PrimitiveType.triangles, 6, gl.ElementType.unsigned_int, 0);

        c.glfwSwapBuffers(instance.window);
        c.glfwPollEvents();
    }
}
