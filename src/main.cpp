//
// Created by jeremy on 2022-04-18.
//

#define GLFW_INCLUDE_NONE

#include <GLFW/glfw3.h>
#include <glad/gl.h>
#include <glm/glm.hpp>
#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>

#include <chrono>
#include <filesystem>
#include <iostream>
#include <regex>
#include <thread>
#include "BF2Path.h"

bool isExistingModWorld(std::filesystem::path &path)
{
    auto parent = path.parent_path();
    auto data_regex = std::regex("^data_[A-Z0-9]{3}$");
    return std::regex_match(parent.string(), data_regex);
}

const char *vertexShaderSrc = R"(
#version 450

layout (location = 0) in vec2 aPos;

void main() {
    gl_Position = vec4(aPos, 1, 1);
}

)";

const char *fragmentShaderSrc = R"(
#version 450

layout (location = 0) out vec4 outColor;

void main() {
    outColor = vec4(1, 0, 0, 1);
}

)";

void message_callback(GLenum source, GLenum type, GLuint id, GLenum severity,
                      GLsizei length, GLchar const *message,
                      void const *user_param) {
    if (severity == GL_DEBUG_SEVERITY_NOTIFICATION)
        return;

    auto const src_str = [source]() {
        switch (source) {
            case GL_DEBUG_SOURCE_API:
                return "API";
            case GL_DEBUG_SOURCE_WINDOW_SYSTEM:
                return "WINDOW SYSTEM";
            case GL_DEBUG_SOURCE_SHADER_COMPILER:
                return "SHADER COMPILER";
            case GL_DEBUG_SOURCE_THIRD_PARTY:
                return "THIRD PARTY";
            case GL_DEBUG_SOURCE_APPLICATION:
                return "APPLICATION";
            case GL_DEBUG_SOURCE_OTHER:
                return "OTHER";
            default:
                return "UNKNOWN SOURCE";
        }
    }();

    auto const type_str = [type]() {
        switch (type) {
            case GL_DEBUG_TYPE_ERROR:
                return "ERROR";
            case GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR:
                return "DEPRECATED_BEHAVIOR";
            case GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:
                return "UNDEFINED_BEHAVIOR";
            case GL_DEBUG_TYPE_PORTABILITY:
                return "PORTABILITY";
            case GL_DEBUG_TYPE_PERFORMANCE:
                return "PERFORMANCE";
            case GL_DEBUG_TYPE_MARKER:
                return "MARKER";
            case GL_DEBUG_TYPE_OTHER:
                return "OTHER";
            default:
                return "UNKNOWN TYPE";
        }
    }();

    auto const severity_str = [severity]() {
        switch (severity) {
            case GL_DEBUG_SEVERITY_NOTIFICATION:
                return "NOTIFICATION";
            case GL_DEBUG_SEVERITY_LOW:
                return "LOW";
            case GL_DEBUG_SEVERITY_MEDIUM:
                return "MEDIUM";
            case GL_DEBUG_SEVERITY_HIGH:
                return "HIGH";
            default:
                return "UNKNOWN SEVERITY";
        }
    }();
    std::cout << src_str << ", " << type_str << ", " << severity_str << ", " << id
              << ": " << message << '\n';
}

int main(int argc, char *argv[]) {
    namespace fs = std::filesystem;

    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 5);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    auto window = glfwCreateWindow(600, 800, "VisualMunge for Linux", nullptr, nullptr);
    if (!window)
        throw std::runtime_error("Error creating glfw window");
    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);

    if (!gladLoaderLoadGL())
        throw std::runtime_error("Error initializing glad");

    /**
     * Initialize ImGui
     */
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 450 core");
    ImGui::StyleColorsClassic();

    glEnable(GL_CULL_FACE);
    glEnable(GL_DEBUG_OUTPUT);
    glDebugMessageCallback(message_callback, nullptr);

    /**
     * Compile shader
     */
    int success;
    char infoLog[512];
    auto vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSrc, 0);
    glCompileShader(vertexShader);

    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(vertexShader, 512, nullptr, infoLog);
        std::cerr << "Vertex shader compilation failed:" << std::endl;
        std::cerr << infoLog << std::endl;
        return 0;
    }

    auto fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSrc, 0);
    glCompileShader(fragmentShader);

    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(fragmentShader, 512, nullptr, infoLog);
        std::cerr << "Fragment shader compilation failed:" << std::endl;
        std::cerr << infoLog << std::endl;
        return 0;
    }

    auto program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);

    glGetProgramiv(program, GL_LINK_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(program, 512, nullptr, infoLog);
        std::cerr << "Shader linking failed:" << std::endl;
        std::cerr << infoLog << std::endl;
        return 0;
    }

    glDetachShader(program, vertexShader);
    glDetachShader(program, fragmentShader);

    /**
     * Create vertex array and buffers
     */
    GLuint vao;
    glCreateVertexArrays(1, &vao);

    glEnableVertexArrayAttrib(vao, 0);
    glVertexArrayAttribFormat(vao, 0, 2, GL_FLOAT, GL_FALSE,
                              offsetof(glm::vec2, x));

    glVertexArrayAttribBinding(vao, 0, 0);

    GLuint vbo;
    glCreateBuffers(1, &vbo);

    GLuint ibo;
    glCreateBuffers(1, &ibo);

    glBindVertexArray(vao);
    glVertexArrayVertexBuffer(vao, 0, vbo, 0, sizeof(glm::vec2));
    glVertexArrayElementBuffer(vao, ibo);
    glUseProgram(program);
    glClearColor(0, 0, 0, 1);

    auto bf2_path = BF2Path();

    if (BF2Path::storage_exists()) {
        bf2_path.storage_read();
    }

    auto current_path = fs::current_path();
    auto parent_path = current_path.parent_path();
    auto munge_path = current_path / "munge.sh";

    if (!fs::exists(munge_path)) {
        // TODO show an error window instead of new world/munge/console
    }

    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        if (!bf2_path.exists()) {
            ImGui::OpenPopup("SWBF2 Path");
            bf2_path.display_prompt();
        }

        std::string menu_action;
        if (ImGui::BeginMainMenuBar()) {
            if (ImGui::BeginMenu("File")) {
                if (ImGui::MenuItem("Quit", "Ctrl+Q")) {
                    menu_action = "Quit";
                    break;
                }
                ImGui::EndMenu();
            }

            if (ImGui::BeginMenu("Tools")) {
                if (ImGui::MenuItem("Set SWBF2 path...")) {
                    // Open file browser to get SWBF2 path
                    menu_action = "SWBF2 Path";
                }
                if (ImGui::MenuItem("Options...")) {
                    // Open options menu
                    menu_action = "Options";
                }
                ImGui::EndMenu();
            }

            if (ImGui::BeginMenu("Help")) {
                if (ImGui::MenuItem("Documentation")) {
                    // Open window with basic help text
                    menu_action = "Documentation";
                }
                if (ImGui::MenuItem("About")) {
                    // Open window with developer info and a hyperlink to the github page
                    menu_action = "About";
                }
                ImGui::EndMenu();
            }
            ImGui::EndMainMenuBar();
        }

        if (menu_action == "SWBF2 Path")
            ImGui::OpenPopup("SWBF2 Path");

        static bool yes;
        static char world_code_buffer[4] = {0};
        static char world_name_buffer[33] = {0};
        static char world_desc_buffer[2049] = {0};
        static bool space_map = false;
        static bool conquest, ctf2, ctf1, assault;
        static ImGuiWindowFlags flags =
                ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoSavedSettings |
                ImGuiWindowFlags_NoCollapse;

        const ImGuiViewport *viewport = ImGui::GetMainViewport();
        auto workSize = ImVec2{viewport->WorkSize.x, viewport->WorkSize.y * 2 / 3};
        auto mungePos = ImVec2{viewport->WorkPos};

        if (bf2_path.exists()) {
            if (!isExistingModWorld(current_path)) {
                ImGui::SetNextWindowPos(viewport->WorkPos);
                ImGui::SetNextWindowSize(workSize);
                ImGui::SetNextWindowBgAlpha(1);
                if (ImGui::Begin("Create New World", &yes, flags)) {
                    {
                        ImGui::Text("3-Letter World Name");
                        ImGui::SameLine();
                        ImGui::SetNextItemWidth(3 * ImGui::GetFontSize());
                        ImGui::InputTextWithHint("##world-code", "ABC", world_code_buffer, 4);
                        ImGui::SameLine();
                        ImGui::Text("Full World Name");
                        ImGui::SameLine();
                        ImGui::SetNextItemWidth(-1);
                        ImGui::InputTextWithHint("##world-name", "Snazzy ModWorld", world_name_buffer, 33);
                    }
                    {
                        ImGui::Text("World Description (3 lines max)");
                        ImGui::SetNextItemWidth(-1);
                        ImGui::InputTextMultiline("##world-desc", world_desc_buffer, 2049);
                    }
                    {
                        ImGui::Checkbox("Space Map", &space_map);
                        ImGui::SameLine(ImGui::GetWindowWidth() / 2);
                        ImGui::BeginGroup();
                        {
                            ImGui::Checkbox("Conquest", &conquest);
                            ImGui::Checkbox("2-Flag CTF", &ctf2);
                            ImGui::Checkbox("1-Flag CTF", &ctf1);
                            ImGui::Checkbox("Assault", &assault);
                        }
                        ImGui::EndGroup();
                    }
                    if (ImGui::Button("Create World")) {
                        // Munge!
                    }
                }
                ImGui::End();
            } else {
                ImGui::SetNextWindowPos(mungePos);
                ImGui::SetNextWindowSize(workSize);
                ImGui::SetNextWindowBgAlpha(1);
                if (ImGui::Begin("Munge", &yes, flags)) {

                }
                ImGui::End();
            }

            auto consolePos = ImVec2{viewport->WorkPos.x, viewport->WorkSize.y * 2 / 3};
            auto consoleSize = ImVec2{viewport->WorkSize.x, viewport->WorkSize.y / 3};
            ImGui::SetNextWindowPos(consolePos);
            ImGui::SetNextWindowSize(consoleSize);
            ImGui::SetNextWindowBgAlpha(1);
            if (ImGui::Begin("Console", &yes, flags)) {

            }
            ImGui::End();
        }

        bf2_path.display_prompt();

        ImGui::Render();
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        glfwSwapBuffers(window);
        glClear(GL_COLOR_BUFFER_BIT);

        std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }

    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

    glfwDestroyWindow(window);
    glfwTerminate();
    return 0;
}