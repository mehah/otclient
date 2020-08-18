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

#ifndef FRAMEWORK_NET_DECLARATIONS_H
#define FRAMEWORK_NET_DECLARATIONS_H

#include <framework/global.h>
#include <boost/asio.hpp>
#include <boost/system/error_code.hpp>

namespace asio = boost::asio;

class InputMessage;
class OutputMessage;
class Connection;
class Protocol;
class ProtocolHttp;
class Server;

typedef stdext::shared_object_ptr<InputMessage> InputMessagePtr;
typedef stdext::shared_object_ptr<OutputMessage> OutputMessagePtr;
typedef stdext::shared_object_ptr<Connection> ConnectionPtr;
typedef stdext::shared_object_ptr<Protocol> ProtocolPtr;
typedef stdext::shared_object_ptr<ProtocolHttp> ProtocolHttpPtr;
typedef stdext::shared_object_ptr<Server> ServerPtr;

#endif
