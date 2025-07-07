const std = @import("std");

const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

pub const Instance = struct {
    window: *c.GLFWwindow,

    pub fn init(wWidth: u32, wHeight: u32, wTitle: [:0]const u8) Instance {
        if (c.glfwInit() != c.GLFW_TRUE) {
            @panic("Unable to initialized GLFW");
        }
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
        c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
        c.glfwWindowHint(c.GLFW_RESIZABLE, c.GLFW_FALSE);

        const window = c.glfwCreateWindow(@intCast(wWidth), @intCast(wHeight), wTitle, null, null) orelse {
            c.glfwTerminate();
            @panic("Failed to create a window");
        };

        return .{
            .window = window,
        };
    }

    pub fn makeCurrent(self: Instance) void {
        c.glfwMakeContextCurrent(self.window);
    }

    pub fn deinit(self: Instance) void {
        c.glfwDestroyWindow(self.window);
        c.glfwTerminate();
    }
};
