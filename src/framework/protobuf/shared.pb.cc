// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: shared.proto

#include "shared.pb.h"

#include <algorithm>

#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/extension_set.h>
#include <google/protobuf/wire_format_lite.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/generated_message_reflection.h>
#include <google/protobuf/reflection_ops.h>
#include <google/protobuf/wire_format.h>
// @@protoc_insertion_point(includes)
#include <google/protobuf/port_def.inc>

PROTOBUF_PRAGMA_INIT_SEG
namespace tibia
{
    namespace protobuf
    {
        namespace shared
        {
            constexpr Coordinate::Coordinate(
              ::PROTOBUF_NAMESPACE_ID::internal::ConstantInitialized)
                : x_(0u)
                , y_(0u)
                , z_(0u)
            {}
            struct CoordinateDefaultTypeInternal
            {
                constexpr CoordinateDefaultTypeInternal()
                    : _instance(::PROTOBUF_NAMESPACE_ID::internal::ConstantInitialized{})
                {}
                ~CoordinateDefaultTypeInternal() {}
                union
                {
                    Coordinate _instance;
                };
            };
            PROTOBUF_ATTRIBUTE_NO_DESTROY PROTOBUF_CONSTINIT CoordinateDefaultTypeInternal _Coordinate_default_instance_;
        }  // namespace shared
    }  // namespace protobuf
}  // namespace tibia
static ::PROTOBUF_NAMESPACE_ID::Metadata file_level_metadata_shared_2eproto[1];
static const ::PROTOBUF_NAMESPACE_ID::EnumDescriptor* file_level_enum_descriptors_shared_2eproto[5];
static constexpr ::PROTOBUF_NAMESPACE_ID::ServiceDescriptor const** file_level_service_descriptors_shared_2eproto = nullptr;

const ::PROTOBUF_NAMESPACE_ID::uint32 TableStruct_shared_2eproto::offsets[] PROTOBUF_SECTION_VARIABLE(protodesc_cold) = {
  PROTOBUF_FIELD_OFFSET(::tibia::protobuf::shared::Coordinate, _has_bits_),
  PROTOBUF_FIELD_OFFSET(::tibia::protobuf::shared::Coordinate, _internal_metadata_),
  ~0u,  // no _extensions_
  ~0u,  // no _oneof_case_
  ~0u,  // no _weak_field_map_
  ~0u,  // no _inlined_string_donated_
  PROTOBUF_FIELD_OFFSET(::tibia::protobuf::shared::Coordinate, x_),
  PROTOBUF_FIELD_OFFSET(::tibia::protobuf::shared::Coordinate, y_),
  PROTOBUF_FIELD_OFFSET(::tibia::protobuf::shared::Coordinate, z_),
  0,
  1,
  2,
};
static const ::PROTOBUF_NAMESPACE_ID::internal::MigrationSchema schemas[] PROTOBUF_SECTION_VARIABLE(protodesc_cold) = {
  { 0, 9, -1, sizeof(::tibia::protobuf::shared::Coordinate)},
};

static ::PROTOBUF_NAMESPACE_ID::Message const* const file_default_instances[] = {
  reinterpret_cast<const ::PROTOBUF_NAMESPACE_ID::Message*>(&::tibia::protobuf::shared::_Coordinate_default_instance_),
};

const char descriptor_table_protodef_shared_2eproto[] PROTOBUF_SECTION_VARIABLE(protodesc_cold) =
"\n\014shared.proto\022\025tibia.protobuf.shared\"-\n"
"\nCoordinate\022\t\n\001x\030\001 \001(\r\022\t\n\001y\030\002 \001(\r\022\t\n\001z\030\003"
" \001(\r*\224\001\n\rPLAYER_ACTION\022\026\n\022PLAYER_ACTION_"
"NONE\020\000\022\026\n\022PLAYER_ACTION_LOOK\020\001\022\025\n\021PLAYER"
"_ACTION_USE\020\002\022\026\n\022PLAYER_ACTION_OPEN\020\003\022$\n"
" PLAYER_ACTION_AUTOWALK_HIGHLIGHT\020\004*\263\005\n\r"
"ITEM_CATEGORY\022\030\n\024ITEM_CATEGORY_ARMORS\020\001\022"
"\031\n\025ITEM_CATEGORY_AMULETS\020\002\022\027\n\023ITEM_CATEG"
"ORY_BOOTS\020\003\022\034\n\030ITEM_CATEGORY_CONTAINERS\020"
"\004\022\034\n\030ITEM_CATEGORY_DECORATION\020\005\022\026\n\022ITEM_"
"CATEGORY_FOOD\020\006\022\036\n\032ITEM_CATEGORY_HELMETS"
"_HATS\020\007\022\026\n\022ITEM_CATEGORY_LEGS\020\010\022\030\n\024ITEM_"
"CATEGORY_OTHERS\020\t\022\031\n\025ITEM_CATEGORY_POTIO"
"NS\020\n\022\027\n\023ITEM_CATEGORY_RINGS\020\013\022\027\n\023ITEM_CA"
"TEGORY_RUNES\020\014\022\031\n\025ITEM_CATEGORY_SHIELDS\020"
"\r\022\027\n\023ITEM_CATEGORY_TOOLS\020\016\022\033\n\027ITEM_CATEG"
"ORY_VALUABLES\020\017\022\034\n\030ITEM_CATEGORY_AMMUNIT"
"ION\020\020\022\026\n\022ITEM_CATEGORY_AXES\020\021\022\027\n\023ITEM_CA"
"TEGORY_CLUBS\020\022\022\"\n\036ITEM_CATEGORY_DISTANCE"
"_WEAPONS\020\023\022\030\n\024ITEM_CATEGORY_SWORDS\020\024\022\034\n\030"
"ITEM_CATEGORY_WANDS_RODS\020\025\022!\n\035ITEM_CATEG"
"ORY_PREMIUM_SCROLLS\020\026\022\035\n\031ITEM_CATEGORY_T"
"IBIA_COINS\020\027\022#\n\037ITEM_CATEGORY_CREATURE_P"
"RODUCTS\020\030*\355\001\n\021PLAYER_PROFESSION\022\"\n\025PLAYE"
"R_PROFESSION_ANY\020\377\377\377\377\377\377\377\377\377\001\022\032\n\026PLAYER_PR"
"OFESSION_NONE\020\000\022\034\n\030PLAYER_PROFESSION_KNI"
"GHT\020\001\022\035\n\031PLAYER_PROFESSION_PALADIN\020\002\022\036\n\032"
"PLAYER_PROFESSION_SORCERER\020\003\022\033\n\027PLAYER_P"
"ROFESSION_DRUID\020\004\022\036\n\032PLAYER_PROFESSION_P"
"ROMOTED\020\n*\203\001\n\023ANIMATION_LOOP_TYPE\022)\n\034ANI"
"MATION_LOOP_TYPE_PINGPONG\020\377\377\377\377\377\377\377\377\377\001\022 \n\034"
"ANIMATION_LOOP_TYPE_INFINITE\020\000\022\037\n\033ANIMAT"
"ION_LOOP_TYPE_COUNTED\020\001*4\n\tHOOK_TYPE\022\023\n\017"
"HOOK_TYPE_SOUTH\020\001\022\022\n\016HOOK_TYPE_EAST\020\002"
;
static ::PROTOBUF_NAMESPACE_ID::internal::once_flag descriptor_table_shared_2eproto_once;
const ::PROTOBUF_NAMESPACE_ID::internal::DescriptorTable descriptor_table_shared_2eproto = {
  false, false, 1357, descriptor_table_protodef_shared_2eproto, "shared.proto",
  &descriptor_table_shared_2eproto_once, nullptr, 0, 1,
  schemas, file_default_instances, TableStruct_shared_2eproto::offsets,
  file_level_metadata_shared_2eproto, file_level_enum_descriptors_shared_2eproto, file_level_service_descriptors_shared_2eproto,
};
PROTOBUF_ATTRIBUTE_WEAK const ::PROTOBUF_NAMESPACE_ID::internal::DescriptorTable* descriptor_table_shared_2eproto_getter()
{
    return &descriptor_table_shared_2eproto;
}

// Force running AddDescriptors() at dynamic initialization time.
PROTOBUF_ATTRIBUTE_INIT_PRIORITY static ::PROTOBUF_NAMESPACE_ID::internal::AddDescriptorsRunner dynamic_init_dummy_shared_2eproto(&descriptor_table_shared_2eproto);
namespace tibia
{
    namespace protobuf
    {
        namespace shared
        {
            const ::PROTOBUF_NAMESPACE_ID::EnumDescriptor* PLAYER_ACTION_descriptor()
            {
                ::PROTOBUF_NAMESPACE_ID::internal::AssignDescriptors(&descriptor_table_shared_2eproto);
                return file_level_enum_descriptors_shared_2eproto[0];
            }
            bool PLAYER_ACTION_IsValid(int value)
            {
                switch (value) {
                case 0:
                case 1:
                case 2:
                case 3:
                case 4:
                return true;
                default:
                return false;
                }
            }

            const ::PROTOBUF_NAMESPACE_ID::EnumDescriptor* ITEM_CATEGORY_descriptor()
            {
                ::PROTOBUF_NAMESPACE_ID::internal::AssignDescriptors(&descriptor_table_shared_2eproto);
                return file_level_enum_descriptors_shared_2eproto[1];
            }
            bool ITEM_CATEGORY_IsValid(int value)
            {
                switch (value) {
                case 1:
                case 2:
                case 3:
                case 4:
                case 5:
                case 6:
                case 7:
                case 8:
                case 9:
                case 10:
                case 11:
                case 12:
                case 13:
                case 14:
                case 15:
                case 16:
                case 17:
                case 18:
                case 19:
                case 20:
                case 21:
                case 22:
                case 23:
                case 24:
                return true;
                default:
                return false;
                }
            }

            const ::PROTOBUF_NAMESPACE_ID::EnumDescriptor* PLAYER_PROFESSION_descriptor()
            {
                ::PROTOBUF_NAMESPACE_ID::internal::AssignDescriptors(&descriptor_table_shared_2eproto);
                return file_level_enum_descriptors_shared_2eproto[2];
            }
            bool PLAYER_PROFESSION_IsValid(int value)
            {
                switch (value) {
                case -1:
                case 0:
                case 1:
                case 2:
                case 3:
                case 4:
                case 10:
                return true;
                default:
                return false;
                }
            }

            const ::PROTOBUF_NAMESPACE_ID::EnumDescriptor* ANIMATION_LOOP_TYPE_descriptor()
            {
                ::PROTOBUF_NAMESPACE_ID::internal::AssignDescriptors(&descriptor_table_shared_2eproto);
                return file_level_enum_descriptors_shared_2eproto[3];
            }
            bool ANIMATION_LOOP_TYPE_IsValid(int value)
            {
                switch (value) {
                case -1:
                case 0:
                case 1:
                return true;
                default:
                return false;
                }
            }

            const ::PROTOBUF_NAMESPACE_ID::EnumDescriptor* HOOK_TYPE_descriptor()
            {
                ::PROTOBUF_NAMESPACE_ID::internal::AssignDescriptors(&descriptor_table_shared_2eproto);
                return file_level_enum_descriptors_shared_2eproto[4];
            }
            bool HOOK_TYPE_IsValid(int value)
            {
                switch (value) {
                case 1:
                case 2:
                return true;
                default:
                return false;
                }
            }

            // ===================================================================

            class Coordinate::_Internal
            {
            public:
                using HasBits = decltype(std::declval<Coordinate>()._has_bits_);
                static void set_has_x(HasBits* has_bits)
                {
                    (*has_bits)[0] |= 1u;
                }
                static void set_has_y(HasBits* has_bits)
                {
                    (*has_bits)[0] |= 2u;
                }
                static void set_has_z(HasBits* has_bits)
                {
                    (*has_bits)[0] |= 4u;
                }
            };

            Coordinate::Coordinate(::PROTOBUF_NAMESPACE_ID::Arena* arena,
                                     bool is_message_owned)
                : ::PROTOBUF_NAMESPACE_ID::Message(arena, is_message_owned)
            {
                SharedCtor();
                if (!is_message_owned) {
                    RegisterArenaDtor(arena);
                }
                // @@protoc_insertion_point(arena_constructor:tibia.protobuf.shared.Coordinate)
            }
            Coordinate::Coordinate(const Coordinate& from)
                : ::PROTOBUF_NAMESPACE_ID::Message(),
                _has_bits_(from._has_bits_)
            {
                _internal_metadata_.MergeFrom<::PROTOBUF_NAMESPACE_ID::UnknownFieldSet>(from._internal_metadata_);
                ::memcpy(&x_, &from.x_,
                  static_cast<size_t>(reinterpret_cast<char*>(&z_) -
                      reinterpret_cast<char*>(&x_)) + sizeof(z_));
                // @@protoc_insertion_point(copy_constructor:tibia.protobuf.shared.Coordinate)
            }

            void Coordinate::SharedCtor()
            {
                ::memset(reinterpret_cast<char*>(this) + static_cast<size_t>(
                    reinterpret_cast<char*>(&x_) - reinterpret_cast<char*>(this)),
                    0, static_cast<size_t>(reinterpret_cast<char*>(&z_) -
                        reinterpret_cast<char*>(&x_)) + sizeof(z_));
            }

            Coordinate::~Coordinate()
            {
                // @@protoc_insertion_point(destructor:tibia.protobuf.shared.Coordinate)
                if (GetArenaForAllocation() != nullptr) return;
                SharedDtor();
                _internal_metadata_.Delete<::PROTOBUF_NAMESPACE_ID::UnknownFieldSet>();
            }

            inline void Coordinate::SharedDtor()
            {
                GOOGLE_DCHECK(GetArenaForAllocation() == nullptr);
            }

            void Coordinate::ArenaDtor(void* object)
            {
                Coordinate* _this = reinterpret_cast<Coordinate*>(object);
                (void)_this;
            }
            void Coordinate::RegisterArenaDtor(::PROTOBUF_NAMESPACE_ID::Arena*)
            {}
            void Coordinate::SetCachedSize(int size) const
            {
                _cached_size_.Set(size);
            }

            void Coordinate::Clear()
            {
                // @@protoc_insertion_point(message_clear_start:tibia.protobuf.shared.Coordinate)
                ::PROTOBUF_NAMESPACE_ID::uint32 cached_has_bits = 0;
                // Prevent compiler warnings about cached_has_bits being unused
                (void)cached_has_bits;

                cached_has_bits = _has_bits_[0];
                if (cached_has_bits & 0x00000007u) {
                    ::memset(&x_, 0, static_cast<size_t>(
                        reinterpret_cast<char*>(&z_) -
                        reinterpret_cast<char*>(&x_)) + sizeof(z_));
                }
                _has_bits_.Clear();
                _internal_metadata_.Clear<::PROTOBUF_NAMESPACE_ID::UnknownFieldSet>();
            }

            const char* Coordinate::_InternalParse(const char* ptr, ::PROTOBUF_NAMESPACE_ID::internal::ParseContext* ctx)
            {
#define CHK_(x) if (PROTOBUF_PREDICT_FALSE(!(x))) goto failure
                _Internal::HasBits has_bits{};
                while (!ctx->Done(&ptr)) {
                    ::PROTOBUF_NAMESPACE_ID::uint32 tag;
                    ptr = ::PROTOBUF_NAMESPACE_ID::internal::ReadTag(ptr, &tag);
                    switch (tag >> 3) {
                        // optional uint32 x = 1;
                    case 1:
                    if (PROTOBUF_PREDICT_TRUE(static_cast<::PROTOBUF_NAMESPACE_ID::uint8>(tag) == 8)) {
                        _Internal::set_has_x(&has_bits);
                        x_ = ::PROTOBUF_NAMESPACE_ID::internal::ReadVarint32(&ptr);
                        CHK_(ptr);
                    } else
                        goto handle_unusual;
                    continue;
                    // optional uint32 y = 2;
                    case 2:
                    if (PROTOBUF_PREDICT_TRUE(static_cast<::PROTOBUF_NAMESPACE_ID::uint8>(tag) == 16)) {
                        _Internal::set_has_y(&has_bits);
                        y_ = ::PROTOBUF_NAMESPACE_ID::internal::ReadVarint32(&ptr);
                        CHK_(ptr);
                    } else
                        goto handle_unusual;
                    continue;
                    // optional uint32 z = 3;
                    case 3:
                    if (PROTOBUF_PREDICT_TRUE(static_cast<::PROTOBUF_NAMESPACE_ID::uint8>(tag) == 24)) {
                        _Internal::set_has_z(&has_bits);
                        z_ = ::PROTOBUF_NAMESPACE_ID::internal::ReadVarint32(&ptr);
                        CHK_(ptr);
                    } else
                        goto handle_unusual;
                    continue;
                    default:
                    goto handle_unusual;
                    }  // switch
                handle_unusual:
                    if ((tag == 0) || ((tag & 7) == 4)) {
                        CHK_(ptr);
                        ctx->SetLastTag(tag);
                        goto message_done;
                    }
                    ptr = UnknownFieldParse(
                        tag,
                        _internal_metadata_.mutable_unknown_fields<::PROTOBUF_NAMESPACE_ID::UnknownFieldSet>(),
                        ptr, ctx);
                    CHK_(ptr != nullptr);
                }  // while
            message_done:
                _has_bits_.Or(has_bits);
                return ptr;
            failure:
                ptr = nullptr;
                goto message_done;
#undef CHK_
            }

            ::PROTOBUF_NAMESPACE_ID::uint8* Coordinate::_InternalSerialize(
                ::PROTOBUF_NAMESPACE_ID::uint8* target, ::PROTOBUF_NAMESPACE_ID::io::EpsCopyOutputStream* stream) const
            {
                // @@protoc_insertion_point(serialize_to_array_start:tibia.protobuf.shared.Coordinate)
                ::PROTOBUF_NAMESPACE_ID::uint32 cached_has_bits = 0;
                (void)cached_has_bits;

                cached_has_bits = _has_bits_[0];
                // optional uint32 x = 1;
                if (cached_has_bits & 0x00000001u) {
                    target = stream->EnsureSpace(target);
                    target = ::PROTOBUF_NAMESPACE_ID::internal::WireFormatLite::WriteUInt32ToArray(1, this->_internal_x(), target);
                }

                // optional uint32 y = 2;
                if (cached_has_bits & 0x00000002u) {
                    target = stream->EnsureSpace(target);
                    target = ::PROTOBUF_NAMESPACE_ID::internal::WireFormatLite::WriteUInt32ToArray(2, this->_internal_y(), target);
                }

                // optional uint32 z = 3;
                if (cached_has_bits & 0x00000004u) {
                    target = stream->EnsureSpace(target);
                    target = ::PROTOBUF_NAMESPACE_ID::internal::WireFormatLite::WriteUInt32ToArray(3, this->_internal_z(), target);
                }

                if (PROTOBUF_PREDICT_FALSE(_internal_metadata_.have_unknown_fields())) {
                    target = ::PROTOBUF_NAMESPACE_ID::internal::WireFormat::InternalSerializeUnknownFieldsToArray(
                        _internal_metadata_.unknown_fields<::PROTOBUF_NAMESPACE_ID::UnknownFieldSet>(::PROTOBUF_NAMESPACE_ID::UnknownFieldSet::default_instance), target, stream);
                }
                // @@protoc_insertion_point(serialize_to_array_end:tibia.protobuf.shared.Coordinate)
                return target;
            }

            size_t Coordinate::ByteSizeLong() const
            {
                // @@protoc_insertion_point(message_byte_size_start:tibia.protobuf.shared.Coordinate)
                size_t total_size = 0;

                ::PROTOBUF_NAMESPACE_ID::uint32 cached_has_bits = 0;
                // Prevent compiler warnings about cached_has_bits being unused
                (void)cached_has_bits;

                cached_has_bits = _has_bits_[0];
                if (cached_has_bits & 0x00000007u) {
                    // optional uint32 x = 1;
                    if (cached_has_bits & 0x00000001u) {
                        total_size += ::PROTOBUF_NAMESPACE_ID::internal::WireFormatLite::UInt32SizePlusOne(this->_internal_x());
                    }

                    // optional uint32 y = 2;
                    if (cached_has_bits & 0x00000002u) {
                        total_size += ::PROTOBUF_NAMESPACE_ID::internal::WireFormatLite::UInt32SizePlusOne(this->_internal_y());
                    }

                    // optional uint32 z = 3;
                    if (cached_has_bits & 0x00000004u) {
                        total_size += ::PROTOBUF_NAMESPACE_ID::internal::WireFormatLite::UInt32SizePlusOne(this->_internal_z());
                    }
                }
                return MaybeComputeUnknownFieldsSize(total_size, &_cached_size_);
            }

            const ::PROTOBUF_NAMESPACE_ID::Message::ClassData Coordinate::_class_data_ = {
                ::PROTOBUF_NAMESPACE_ID::Message::CopyWithSizeCheck,
                Coordinate::MergeImpl
            };
            const ::PROTOBUF_NAMESPACE_ID::Message::ClassData* Coordinate::GetClassData() const { return &_class_data_; }

            void Coordinate::MergeImpl(::PROTOBUF_NAMESPACE_ID::Message* to,
                                  const ::PROTOBUF_NAMESPACE_ID::Message& from)
            {
                static_cast<Coordinate*>(to)->MergeFrom(
                    static_cast<const Coordinate&>(from));
            }

            void Coordinate::MergeFrom(const Coordinate& from)
            {
                // @@protoc_insertion_point(class_specific_merge_from_start:tibia.protobuf.shared.Coordinate)
                GOOGLE_DCHECK_NE(&from, this);
                ::PROTOBUF_NAMESPACE_ID::uint32 cached_has_bits = 0;
                (void)cached_has_bits;

                cached_has_bits = from._has_bits_[0];
                if (cached_has_bits & 0x00000007u) {
                    if (cached_has_bits & 0x00000001u) {
                        x_ = from.x_;
                    }
                    if (cached_has_bits & 0x00000002u) {
                        y_ = from.y_;
                    }
                    if (cached_has_bits & 0x00000004u) {
                        z_ = from.z_;
                    }
                    _has_bits_[0] |= cached_has_bits;
                }
                _internal_metadata_.MergeFrom<::PROTOBUF_NAMESPACE_ID::UnknownFieldSet>(from._internal_metadata_);
            }

            void Coordinate::CopyFrom(const Coordinate& from)
            {
                // @@protoc_insertion_point(class_specific_copy_from_start:tibia.protobuf.shared.Coordinate)
                if (&from == this) return;
                Clear();
                MergeFrom(from);
            }

            bool Coordinate::IsInitialized() const
            {
                return true;
            }

            void Coordinate::InternalSwap(Coordinate* other)
            {
                using std::swap;
                _internal_metadata_.InternalSwap(&other->_internal_metadata_);
                swap(_has_bits_[0], other->_has_bits_[0]);
                ::PROTOBUF_NAMESPACE_ID::internal::memswap<
                    PROTOBUF_FIELD_OFFSET(Coordinate, z_)
                    + sizeof(Coordinate::z_)
                    - PROTOBUF_FIELD_OFFSET(Coordinate, x_)>(
                        reinterpret_cast<char*>(&x_),
                        reinterpret_cast<char*>(&other->x_));
            }

            ::PROTOBUF_NAMESPACE_ID::Metadata Coordinate::GetMetadata() const
            {
                return ::PROTOBUF_NAMESPACE_ID::internal::AssignDescriptors(
                    &descriptor_table_shared_2eproto_getter, &descriptor_table_shared_2eproto_once,
                    file_level_metadata_shared_2eproto[0]);
            }

            // @@protoc_insertion_point(namespace_scope)
        }  // namespace shared
    }  // namespace protobuf
}  // namespace tibia
PROTOBUF_NAMESPACE_OPEN
template<> PROTOBUF_NOINLINE::tibia::protobuf::shared::Coordinate* Arena::CreateMaybeMessage< ::tibia::protobuf::shared::Coordinate >(Arena* arena)
{
    return Arena::CreateMessageInternal< ::tibia::protobuf::shared::Coordinate >(arena);
}
PROTOBUF_NAMESPACE_CLOSE

// @@protoc_insertion_point(global_scope)
#include <google/protobuf/port_undef.inc>
