#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <cjson/cJSON.h>
#include "client.h"
#include "image_file_accepted.h"

bool image_file_accepted(struct group_list_t *group) {
    glog2(group, "mod_image_file_accepted: Checking file %s...", group->fileinfo.name);

    FILE *file = fopen("/opt/virt_data/images.json", "r");
    if (!file) {
        glog2(group, "mod_image_file_accepted: Could not open images.json file.");
        return false;
    }

    fseek(file, 0, SEEK_END);
    long file_size = ftell(file);
    fseek(file, 0, SEEK_SET);

    char *file_contents = malloc(file_size + 1);
    if (!file_contents) {
        glog2(group, "mod_image_file_accepted: Could not allocate memory.");
        fclose(file);
        return false;
    }

    fread(file_contents, 1, file_size, file);
    file_contents[file_size] = '\0';
    fclose(file);

    cJSON *json = cJSON_Parse(file_contents);
    free(file_contents);

    if (!json) {
        glog2(group, "mod_image_file_accepted: Error parsing JSON: %s\n", cJSON_GetErrorPtr());
        return false;
    }

    cJSON *images = cJSON_GetObjectItemCaseSensitive(json, "images");
    if (!images) {
        glog2(group, "mod_image_file_accepted: No images object found in JSON\n");
        cJSON_Delete(json);
        return false;
    }

    cJSON *image_item = NULL;
    cJSON_ArrayForEach(image_item, images) {
        cJSON *image_file = cJSON_GetObjectItemCaseSensitive(image_item, "image_file");
        if (image_file && cJSON_IsString(image_file) && (strcmp(image_file->valuestring, group->fileinfo.name) == 0)) {
            glog2(group, "mod_image_file_accepted: Image accepted.");
            cJSON_Delete(json);
            return true;
        }
    }

    cJSON_Delete(json);
    glog2(group, "mod_image_file_accepted: Image not accepted.");
    return false;
}
