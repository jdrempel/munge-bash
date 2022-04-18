#include <gtkmm.h>

#include <cctype>
#include <filesystem>
#include <fstream>
#include <functional>
#include <iostream>
#include <regex>
#include <string>

bool check(const std::string &prompt, const std::string &def)
{
    std::string input;
    std::string options;
    if (def == "Y" || def == "y") {
        options = "(Y/n)";
    } else {
        options = "(y/N)";
    }
    std::cout << prompt << " " << options;
    std::getline(std::cin, input);

    if (input.empty())
        input = def;

    if (input == "Y" || input == "y")
        return true;

    return false;
}

bool isValidLanguage(const std::string &lang)
{
    auto languages = std::regex("^(de|en|es|fr|it|ja|uk)?$", std::regex::icase);
    return std::regex_match(lang, languages);
}

std::string getLongLanguageName(std::string &lang)
{
    if (lang == "DE") return "GERMAN";
    if (lang == "EN") return "ENGLISH";
    if (lang == "ES") return "SPANISH";
    if (lang == "FR") return "FRENCH";
    if (lang == "IT") return "ITALIAN";
    if (lang == "JA") return "JAPANESE";
    if (lang == "UK") return "UK";
}

bool isValidPlatform(const std::string &platform)
{
    auto platforms = std::regex("^(pc|ps2|xbox)?$", std::regex::icase);
    return std::regex_match(platform, platforms);
}

int main()
{
    /*
     * - Check the current directory
     * - See if the BF2 directory has been set and if not, prompt for it
     * - Prompt for:
     *   - common
     *   - load
     *   - shell
     *   - sides
     *     - EVERYTHING
     *     - NOTHING
     *     - <side> (list dirs in data_ABC/Sides)
     *     - gcw
     *     - cw
     *   - sound
     *   - worlds
     *     - EVERYTHING
     *     - NOTHING
     *     - <world> (list dirs in data_ABC/Worlds)
     * - Run the scripts
     * - Copy results to BF2 dir
     */
    namespace fs = std::filesystem;

    auto current_path = fs::current_path();
    // TODO re-enable this check
    // if (current_path.parent_path() != "_BUILD") {
    //     std::cerr << "Parent directory is " << current_path.stem() << ". Please check that visualmunge is placed"
    //                                                                   " in data_ABC/_BUILD before running it."
    //                                                                   << std::endl;
    //     exit(1);
    // }

    auto munge_path = current_path / "munge.sh";
    if (!fs::exists(munge_path)) {
        std::cerr << "File munge.sh not found. Please check that the munge-bash files are placed correctly in data_ABC/"
                     "_BUILD/ before running visualmunge." << std::endl;
        exit(1);
    }

    std::string bf2_path_str;
    auto bf2_storage_path = current_path / ".swbf2";
    if (fs::exists(bf2_storage_path)) {
        // read the file to get the absolute path of BF2 installation
        std::ifstream bf2_file;
        bf2_file.open(bf2_storage_path, std::ios::in);
        if (!bf2_file) {
            std::cerr << "File .swbf2 not found." << std::endl;
            exit(1);
        }
        std::getline(bf2_file, bf2_path_str);
        bf2_file.close();
    } else {
        // prompt for the path, create the file, store the path
        std::cout << "Please enter the absolute path to your SWBF2 GameData directory:" << std::endl;
        std::getline(std::cin, bf2_path_str);
        std::ofstream bf2_file;
        bf2_file.open(bf2_storage_path, std::ios::out);
        if (!bf2_file) {
            std::cerr << "File .swbf2 could not be created." << std::endl;
            exit(1);
        }
        bf2_file << bf2_path_str << std::endl;
        bf2_file.close();
    }

    if (bf2_path_str.empty()) {
        std::cerr << "Invalid SWBF2 GameData directory (empty)." << std::endl;
        exit(1);
    }

    std::string args;

    std::string platform;
    std::cout << "Platform (PC|ps2|xbox): " << std::flush;
    std::getline(std::cin, platform);
    if (!isValidPlatform(platform)) {
        std::cerr << "Invalid platform entered." << std::endl;
        exit(1);
    }
    if (platform.empty()) {
        platform = "pc";
    }
    std::transform(
            platform.begin(),
            platform.end(),
            platform.begin(),
            std::ptr_fun<int, int>(std::toupper)
            );

    args += " --platform " + platform;

    std::string language;
    std::cout << "Language (EN|de|es|fr|it|ja|uk): " << std::flush;
    std::getline(std::cin, language);
    if (!isValidLanguage(language)) {
        std::cerr << "Invalid language entered." << std::endl;
        exit(1);
    }
    if (language.empty()) {
        language = "ENGLISH";
    }
    std::transform(
            language.begin(),
            language.end(),
            language.begin(),
            std::ptr_fun<int, int>(std::toupper)
            );
    language = getLongLanguageName(language);

    args += " --language " + language;

    bool munge_common = check("Munge common", "Y");
    bool munge_load = check("Munge load", "N");
    bool munge_localize = check("Munge localize", "N");
    bool munge_movies = check("Munge movies", "N");
    bool munge_shell = check("Munge shell", "N");
    bool munge_sound = check("Munge sound", "N");

    // TODO localize sides worlds

    if (munge_common) {
        args += " --common";
    }

    if (munge_load) {
        args += " --load";
    }

    if (munge_localize) {
        args += " --localize";
    }

    if (munge_movies) {
        args += " --movies";
    }

    if (munge_shell) {
        args += " --shell";
    }

    if (munge_sound) {
        args += " --sound";
    }

    std::string exe = "./munge.sh" + args;

    std::system(exe.c_str());

    return 0;
}
