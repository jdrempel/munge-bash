//
// Created by jeremy on 2022-04-19.
//

#ifndef VISUALMUNGE_BF2PATH_H
#define VISUALMUNGE_BF2PATH_H

#include <imgui.h>

#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>


class BF2Path {
private:
    static std::filesystem::path storage_path;
    std::filesystem::path gamedata_path;

public:
    BF2Path();
    ~BF2Path();

    BF2Path(BF2Path &&) noexcept;
    BF2Path &operator=(BF2Path &&) noexcept;

    static bool storage_exists() { return std::filesystem::exists(storage_path); }
    [[nodiscard]] bool exists() const { return std::filesystem::exists(gamedata_path); }

    void storage_read();
    void storage_write();

    void set_path(const std::string &new_path);

    void display_prompt();

};


#endif //VISUALMUNGE_BF2PATH_H
