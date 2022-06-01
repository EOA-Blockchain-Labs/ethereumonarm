
SEARCH_PATH="$1"
SEARCH="$2"
REPLACE="$3"

find ${SEARCH_PATH} -type f -name "*${SEARCH}*" | while read FILENAME ; do
    NEW_FILENAME="$(echo ${FILENAME} | sed -e "s/${SEARCH}/${REPLACE}/g")";
    mv "${FILENAME}" "${NEW_FILENAME}";
done

