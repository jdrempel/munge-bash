//
// Created by jeremy on 2022-04-19.
//

#include "BF2Path.h"


BF2Path::BF2Path() = default;
BF2Path::~BF2Path() = default;
BF2Path::BF2Path(BF2Path &&) noexcept = default;
BF2Path &BF2Path::operator=(BF2Path &&) noexcept = default;

std::filesystem::path BF2Path::storage_path = std::filesystem::current_path() / ".swbf2";

/**
 * Attempt to open the storage file ./.swbf2 and read its first line into the internal path variable.
 * @throws runtime_error If the storage file cannot be opened for some reason
 */
void BF2Path::storage_read()
{
    std::ifstream read_file;
    read_file.open(storage_path, std::ios::in);
    if (!read_file) {
        std::cerr << "File .swbf2 not opened." << std::endl;
        throw std::runtime_error(".swbf2 not opened");
    }
    std::string path_string;
    std::getline(read_file, path_string);
    read_file.close();
    gamedata_path = path_string;
}

/**
 * Attempt to write the BF2 GameData path as a string into the storage file ./.swbf2.
 * @throws runtime_error If the storage file cannot be opened for some reason
 */
void BF2Path::storage_write()
{
    std::ofstream write_file;
    write_file.open(storage_path, std::ios::out);
    if (!write_file) {
        std::cerr << "File .swbf2 not found or able to be created." << std::endl;
        throw std::runtime_error(".swbf2 not opened");
    }
    write_file << gamedata_path.string() << std::endl;
    write_file.close();
}

/**
 * Sets the value of gamedata_path to the path specified by new_path.
 * @param new_path A string representation of the new gamedata path
 */
void BF2Path::set_path(const std::string &new_path)
{
    gamedata_path = new_path;
}

void BF2Path::display_prompt()
{
    using namespace ImGui;

    static char path_chars[1025] = { 0 };

    auto path_str_chars = gamedata_path.c_str();
    memcpy(path_chars, path_str_chars, gamedata_path.string().size()+1);

    if (BeginPopupModal("SWBF2 Path", nullptr)) {
        Text("Battlefront 2 GameData Directory");
        InputText("##bf2-path", path_chars, sizeof(path_chars), 0, nullptr, (void *)gamedata_path.c_str());

        if (Button("OK")) {
            if (std::filesystem::exists(path_chars)) {
                set_path(path_chars);
                storage_write();
                CloseCurrentPopup();
            }
        }

        EndPopup();
    }
}
