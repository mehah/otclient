/**
 * Canary Lib - Canary Project a free 2D game platform
 * Copyright (C) 2020  Lucas Grossi <lucas.ggrossi@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "protocol.h"
#include "connection.h"

/**
 * Controls the content message routing.
 * It will identify the type and call the proper parser method.
*/
void Protocol::parseContentMessage(const CanaryLib::ContentMessage *content_msg) {
  for (int i = 0; i < content_msg->data()->size(); i++) {
    switch (auto dataType = content_msg->data_type()->GetEnum<CanaryLib::DataType>(i)) {
      case CanaryLib::DataType_CharactersListData:
        parseCharacterList(content_msg->data()->GetAs<CanaryLib::CharactersListData>(i));
        break;

      case CanaryLib::DataType_ErrorData:
        parseError(content_msg->data()->GetAs<CanaryLib::ErrorData>(i));
        break;

      case CanaryLib::DataType_RawData:
        parseRawData(content_msg->data()->GetAs<CanaryLib::RawData>(i));
        break;
      
      case CanaryLib::DataType_NONE:
      default:
        spdlog::warn("[Protocol::parseContentMessage] Invalid {} content message data type was skipped.", dataType);
        break;
    }
  }

  if (m_connection && m_connection->isConnected()) recv();
}

void Protocol::parseRawData(const CanaryLib::RawData *raw_data) {
  m_inputMessage->write(raw_data->body()->data(), raw_data->size(), CanaryLib::MESSAGE_OPERATION_PEEK);
  onRecv(m_inputMessage);
}

